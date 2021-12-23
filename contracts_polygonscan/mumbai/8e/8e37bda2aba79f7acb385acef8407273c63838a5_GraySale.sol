// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Safemath.sol";
import "./Ownable.sol";


struct Book { 
   string title;
   string author;
   uint book_id;
}

contract GraySale is Ownable{

    using SafeMath for uint256;
    IERC20 public dai;
    uint256 public daiprice = 1000000000000000000;
    uint256 public sumMoney = 0;
    mapping(uint=>address[]) public userBetArr;
    mapping(address=>mapping(uint=>address[])) public userBetArr1;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    function bet() callerIsUser
        external
    {
      
        dai.transferFrom(msg.sender, address(this), 1 ether);
        //sumMoney += daiprice;
        //userBetArr[number].push(msg.sender);
    }


    function draw() public returns(uint256) {
        uint randNum = rand(100000);
        for(uint i=0;i<userBetArr[randNum].length;i++){
            dai.transferFrom(address(this), userBetArr[randNum][i], sumMoney / userBetArr[randNum].length);
        }
        return randNum;
    }


    function setDAIAddress(address _daiAddr) onlyOwner external onlyOwner{
        dai = IERC20(_daiAddr);
    }

    function withdrawDAI(address _to, uint256 _amount) external onlyOwner {
        dai.transfer(_to, _amount);
    }


    function rand(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length;
    }

    

    
}