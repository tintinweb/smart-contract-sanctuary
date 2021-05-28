/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

//SPDX-License-Identifier: Apache-2.0;
pragma solidity ^0.7.6;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Barbecue {
    
    using SafeMath for uint256;
    uint256 constant EXCHANGE_RATE = 10;
    
    event Exchanged(address indexed from, uint256 ethValue, uint256 wurstValue);
    
    ERC20Interface public tokenContract = ERC20Interface(address(0x67e74603DF95cAbBEbC6795478c2402A01eA1517));
    address payable public fundingWallet = payable(0x67E0023d1E7176Cdaf65a9afA374D774484839e0);

    receive() external payable {
        address from = msg.sender;
        uint256 ethValue = msg.value;
        require(ethValue > 0, "sent eth has to be greater than 0");
        uint256 wurstValue = ethValue.div(EXCHANGE_RATE);
        require(wurstValue > 0, "exchanged wurstValue has to be greater than 0");
        
        require(tokenContract.transfer(from, wurstValue), "wurst transfer failed");
        emit Exchanged(from, ethValue, wurstValue);
    }
    
    function withdraw() external payable {
        require(msg.sender == fundingWallet, "only the funding wallet can issue a withdraw");
        fundingWallet.transfer(address(this).balance);
    }
}

contract CheapBarbecue {
    
    using SafeMath for uint256;
    uint256 constant EXCHANGE_RATE = 100;
    
    event Exchanged(address indexed from, uint256 ethValue, uint256 wurstValue);
    
    ERC20Interface public tokenContract = ERC20Interface(address(0x67e74603DF95cAbBEbC6795478c2402A01eA1517));
    address payable public fundingWallet = payable(0x67E0023d1E7176Cdaf65a9afA374D774484839e0);

    receive() external payable {
        address from = msg.sender;
        uint256 ethValue = msg.value;
        require(ethValue > 0, "sent eth has to be greater than 0");
        uint256 wurstValue = ethValue.mul(EXCHANGE_RATE);
        require(wurstValue > 0, "exchanged wurstValue has to be greater than 0");
        
        require(tokenContract.transfer(from, wurstValue), "wurst transfer failed");
        emit Exchanged(from, ethValue, wurstValue);
    }
    
    function withdraw() external payable {
        require(msg.sender == fundingWallet, "only the funding wallet can issue a withdraw");
        fundingWallet.transfer(address(this).balance);
    }
}