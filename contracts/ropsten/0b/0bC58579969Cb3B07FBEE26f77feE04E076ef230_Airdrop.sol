pragma solidity ^0.4.26;
import './interfaces/ERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';

contract Airdrop is Ownable {

    struct Investor {
        uint256 amountLeft;
        bool locked;
    }

    ERC20 public Token;

    mapping(address => bool) public whitelisted;
    mapping(address => Investor) public investorDetails;

    event LogWhitelisted(address _investor, uint256 _amount, uint256 _timestamp);

    /**
     * @dev constructor is getting tokens from the token contract
     * @param _token Address of the token
     * @return ERC20 standard token 
     */
    constructor(address _token) public {
        Token = ERC20(_token);
    }


    /**
     * @notice Use to whitelist the investor
     * @param _investorAddresses Array of investors need to whitelist
     * only be called by the owner
     */

    function whitelist(address[] _investorAddresses,uint256[] _tokenAmount) external onlyOwner {
        require(_investorAddresses.length == _tokenAmount.length,"Input array's length mismatch");
        for (uint i = 0; i < _investorAddresses.length; i++) {
            whitelisted[_investorAddresses[i]] = true;
            investorDetails[_investorAddresses[i]] = Investor(_tokenAmount[i],false);
            emit LogWhitelisted(_investorAddresses[i], _tokenAmount[i], now);
        }
    }

     /**
      * @notice user can claim their airdrop tokens 
      */
    function claimTokens() external {
        require(whitelisted[msg.sender]);
        require(!investorDetails[msg.sender].locked);
        uint256 _amount = investorDetails[msg.sender].amountLeft;
        investorDetails[msg.sender] = Investor(0, true);
        Token.transfer(msg.sender, _amount);
    } 
    
    /**
     * @dev This function is used to sort the array of address and token to send tokens 
     * @param _investorsAdd Address array of the investors
     * @param _tokenVal Array of the tokens
     * @return tokens Calling function to send the tokens
     */
    function airdropTokenDistributionMulti(address[] _investorsAdd, uint256[] _tokenVal) public onlyOwner  returns (bool success){
        require(_investorsAdd.length == _tokenVal.length, "Input array's length mismatch");
        for(uint i = 0; i < _investorsAdd.length; i++ ){
            require(airdropTokenDistribution(_investorsAdd[i], _tokenVal[i]));
        }
        return true;
    }

    /**
     * @dev This function is used to get token balance at oddresses  from the array
     * @param _investorsAdd Array if address of the investors
     * @param _tokenVal Array of tokens to be send
     * @return bal Balance 
     */
    function airdropTokenDistribution(address _investorsAdd, uint256 _tokenVal) public onlyOwner returns (bool success){
        require(_investorsAdd != owner, "Reciever should not be the owner of the contract");
        require(Token.transfer(_investorsAdd, _tokenVal));
        return true;
    }

    /**
     * @dev This function is used to add remaining token balance to the owner address
     * @param _tokenAddress Address of the token contract
     * @return true  
     */
    function withdrawTokenBalance(address _tokenAddress) public onlyOwner returns (bool success){
        require(Token.transfer(_tokenAddress, Token.balanceOf(address(this))));
        return true;
    }

    /**
     * @dev This function is used to add remaining balance to the owner address
     * @return true 
     */
    function withdrawEtherBalance() public onlyOwner returns (bool success){
        owner.transfer(address(this).balance);
        return true;
    }
}

pragma solidity ^0.4.26;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
  function balanceOf(address _owner) external view returns (uint256);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function approve(address _spender, uint256 _value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.26;

/*
Copyright (c) 2016 Smart Contract Solutions, Inc.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

pragma solidity ^0.4.26;
/*
Copyright (c) 2016 Smart Contract Solutions, Inc.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}