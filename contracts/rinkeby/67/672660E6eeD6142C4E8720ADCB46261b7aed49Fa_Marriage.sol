// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.6.0;


contract Marriage{


    struct  couple{
        address  Bride;
        address  BGroom;
        uint  price;
        uint status; //0= marrid and 1 = unmarrid
        uint password;
    }

    couple[] public couples;

    function registration(address _BGroom)  public payable  {
        if (CheckIfMarrid(msg.sender) == 1 && CheckIfMarrid(_BGroom) == 1){
            couples.push(
            couple(
                msg.sender,
                _BGroom,
                msg.value,
                0,
                10
            )
            );
        }
    }

    function CheckIfMarrid(address add) public view returns(uint){
        for(uint cup=0;cup<couples.length;cup++){
                if (couples[cup].Bride == add || couples[cup].BGroom == add ) {
                    if (couples[cup].status==0){
                        return 0;
                    }
                }
                }
        return 1;
    }
    
    function viewCoupleFixedMoney(uint index) public view returns(uint){
        return couples[index].price;
    }

    function TotalRegistry() public view returns(uint){
        return couples.length;
    }
    

    function varifyMarriage(address one, address two) public view returns (uint){
        for(uint cup=0;cup<couples.length;cup++){
                if (couples[cup].Bride == one || couples[cup].Bride == two ) {
                        if (couples[cup].BGroom == one || couples[cup].BGroom == two ) {
                            if (couples[cup].status==0){
                                return couples[cup].price;
                            }
                            
                        }
                }
        }
        return 0;
    }


    function Divorce(address add,uint password) payable public{
        for(uint cup=0;cup<couples.length;cup++){
                if (couples[cup].Bride == add || couples[cup].Bride == add  && couples[cup].Bride == msg.sender || couples[cup].Bride ==  msg.sender ) {
                        if (couples[cup].password == password ) {
                            couples[cup].status=1;
                            couples[cup].price = 1;
                            payable(msg.sender).transfer(couples[cup].price);
                            
                        }
                }
        }


    }


}