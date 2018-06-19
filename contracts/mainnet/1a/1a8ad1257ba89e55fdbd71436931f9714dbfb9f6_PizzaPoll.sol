pragma solidity ^0.4.13;

contract PizzaPoll {
    mapping (address => bool) pizzaIsLiked;
    mapping (address => uint) likeCount;
    mapping (address => uint) dislikeCount;

    function PizzaPoll() { 
        likeCount[msg.sender] = 0;
        dislikeCount[msg.sender] = 0;
    }

    function GetLikeCount() returns (uint count){
        return likeCount[msg.sender];
    }

    function GetDislikeCount() returns (uint count) {
        return dislikeCount[msg.sender];
    }

    function Vote (address voterAddress, bool isLiked)
    {
        pizzaIsLiked[voterAddress] = isLiked;

        if (isLiked)
        {
            likeCount[msg.sender] += 1;    
        }
        else
        {
            dislikeCount[msg.sender] += 1;
        }
    }
}