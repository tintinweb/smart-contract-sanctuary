/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.4.24;


library SafeMath {
    
function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

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


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 contract Value{
    address private userId;
    string private name;
    uint256 private quantity;
    
    function setName(string _name) public {
        name = _name;
    }
    
    function setQuantity(uint _quantity) public {
        quantity = _quantity;
    }
    
    function getName() public  returns(string memory){
        return name;
    }

     function getQuantity() public  returns(uint){
         return quantity;
     }
     
     function getUserId() public  returns(address){
         return userId;
     }
 }


contract TestTask is Value{
    using SafeMath for uint256;
    
    Value [] private ask ; // req to sell
    Value [] private bid; // req to buy
    


 function _sell(string memory _name, uint _quantity) private {
        Value temp = new Value();
        if(bid.length > 0){
            for(uint j = 0;j <= bid.length;j++){
                       if(keccak256(abi.encodePacked(bid[j].getName())) == keccak256(abi.encodePacked(_name))){
                      if(bid[j].getQuantity() > _quantity){
                          bid[j].setQuantity(bid[j].getQuantity().sub(_quantity));
                          return;
                      }else if(bid[j].getQuantity() == _quantity){
                          removeByIndexBidArray(j);
                          return;
                      } else{
                      temp.setName(_name);
                      temp.setQuantity(_quantity.sub(bid[j].getQuantity()));
                      ask.push(temp);
                      removeByIndexBidArray(j);
                      return;  
                      }
                  }else{
                    if(ask.length > 0){
                        for(uint m = 0;m < ask.length;m++){
                         if(keccak256(abi.encodePacked(ask[m].getName())) == keccak256(abi.encodePacked(_name))){
                            ask[m].setQuantity(ask[m].getQuantity().add(_quantity));
                            return;
                 }else{
                        temp.setName(_name);
                        temp.setQuantity(_quantity);
                        ask.push(temp);  
                        return;
                 }
             }
         }
         temp.setName(_name);
         temp.setQuantity(_quantity);
         ask.push(temp);  
         return;
    }
            }
        }else{
           if(ask.length > 0){
             for(uint i = 0;i < ask.length;i++){
                 if(keccak256(abi.encodePacked(ask[i].getName())) == keccak256(abi.encodePacked(_name))){
                     ask[i].setQuantity(ask[i].getQuantity().add(_quantity));
                     return;
                 }else {
                     temp.setName(_name);
                     temp.setQuantity(_quantity);
                     ask.push(temp);
                     return;
                 }
             }
         }
         temp.setName(_name);
         temp.setQuantity(_quantity);
         ask.push(temp);
         return;
    }
    }
    
    
    function _buy(string memory _name, uint _quantity) private {
        Value temp = new Value();
        if(ask.length > 0){
              for(uint m = 0; m < ask.length;m++){
                  if(keccak256(abi.encodePacked(ask[m].getName())) == keccak256(abi.encodePacked(_name))){
                      if(ask[m].getQuantity() > _quantity){
                          ask[m].setQuantity(ask[m].getQuantity().sub(_quantity));
                          return;
                      }else if(ask[m].getQuantity() == _quantity){
                          removeByIndexAskArray(m);
                      }else{
                            temp.setName(_name);
                            temp.setQuantity(_quantity.sub(ask[m].getQuantity()));
                            bid.push(temp);
                            removeByIndexAskArray(m);
                            return;  
                      }
                  }else{
                    if(bid.length > 0){
                        for(uint p = 0;p < bid.length;p++){
                            if(keccak256(abi.encodePacked(bid[p].getName())) == keccak256(abi.encodePacked(_name))){
                                bid[p].setQuantity(bid[p].getQuantity().add(_quantity));
                                return;
                 }
             }
         }
         temp.setName(_name);
         temp.setQuantity(_quantity);
         bid.push(temp);
         return;
    }
              }
              
        }else{
           if(bid.length > 0){
             for(uint i = 0;i < bid.length;i++){
                 if(keccak256(abi.encodePacked(bid[i].getName())) == keccak256(abi.encodePacked(_name))){
                     bid[i].setQuantity(bid[i].getQuantity().add(_quantity));
                     return;
                 }
             }
         }
         temp.setName(_name);
         temp.setQuantity(_quantity);
         bid.push(temp);
         return;
    }
}

    function abs(int value) private returns(int) {
        return value < 0 ? -value : value;
    }   

    function put(string _type,int _quantity) public {
        if(_quantity > 0){
            _buy(_type,uint(abs(_quantity)));
        }else {
            _sell(_type,uint(abs(_quantity)));
        }
    }
    
    // function accept(address _acceptUserId,string memory _name,int _quantity) public {
    //     Value temp = new Value();
    //     if(_quantity > 0){
    //         for(uint i = 0;i < ask.length;i++){
    //             if(_acceptUserId == ask[i].getUserId() && 
    //             ask[i].getQuantity() > uint(abs(_quantity)) &&
    //             keccak256(abi.encodePacked(ask[i].getName())) == keccak256(abi.encodePacked(_name))){
    //                 ask[i].setQuantity(ask[i].getQuantity().sub(uint(abs(_quantity))));
    //                 // temp.setName(_name);
    //                 // temp.setQuantity(uint(abs(_quantity)));
    //                 // bid.push(temp);
    //                 return;
    //             }
    //         }
    //     }else if(_quantity < 0){
            
    //     }else {
            
    //     }
        
    // }
    
    
    function removeByIndexAskArray(uint index) private returns(Value[]) {
        if (index >= ask.length) return;

        for (uint i = index; i<ask.length-1; i++){
            ask[i] = ask[i+1];
        }
        delete ask[ask.length-1];
        ask.length--;
        return ask;
    }
    
   function removeByIndexBidArray(uint index) private returns(Value[]) {
        if (index >= bid.length) return;

        for (uint i = index; i<bid.length-1; i++){
            bid[i] = bid[i+1];
        }
        delete bid[bid.length-1];
        bid.length--;
        return bid;
    }
   
    function getAllRequests() public view returns(uint[]){
      uint[] tempArrays;
       
       if(ask.length > 0){
           for(uint i = 0;i < ask.length;i++){
               tempArrays.push(ask[i].getQuantity());
           }
       }
        if(bid.length > 0){
            for(uint j = 0;j < bid.length;j++){
                tempArrays.push(bid[j].getQuantity());
            }
        }
        return tempArrays;
    }

    
}