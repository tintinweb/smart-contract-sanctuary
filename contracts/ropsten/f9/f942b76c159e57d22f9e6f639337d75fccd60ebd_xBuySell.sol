/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity 0.6.6;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


contract xBuySell {
    using SafeMath for uint256;
    
    
    mapping (string => uint) public buyX;
    mapping (string => uint) public sellX;
    
    function buy(string memory id, uint quantity) public {
        if(sellX[id] > 0){
            if(quantity >= sellX[id]){
                buyX[id] = quantity.sub(sellX[id]);
                sellX[id] = 0;
            }else {
                sellX[id] = sellX[id].sub(quantity);
                buyX[id] = 0;
            }
            
        }else{
            buyX[id].add(quantity);
        }
    }
    
    function sell(string memory id, uint quantity) public {
        if(buyX[id]>0){
            if(quantity >= buyX[id]){
                sellX[id] = quantity.sub(buyX[id]);
                buyX[id] = 0;
            }else{
                buyX[id] = buyX[id].sub(quantity);
                sellX[id] = 0;
            }
        }else{
            sellX[id].add(quantity);
        }
    }
    
    function getSellXById(string memory id) public view returns(uint){
        sellX[id].add(1);
        return sellX[id];
    }
    
    function getBuyXById(string memory id) public view returns(uint){
        return buyX[id];
    }
    
}