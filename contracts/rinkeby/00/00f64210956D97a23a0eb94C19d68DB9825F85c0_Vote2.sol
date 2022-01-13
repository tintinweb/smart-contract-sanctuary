/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity=0.8.7;

contract Vote2{
    event Voted(address );

    mapping(address=>bool) public voted;

    uint256 public endTime;
    uint256 public a;
    uint256 public b;
    uint256 public c;

    constructor (uint256 _endTime){
        endTime = _endTime;
    }

    function votes() public view returns(uint256){
        return a+b+c;
    }

    event Voted(address indexed voter,uint8 perposal);

    function vote(uint8 _proposal)public {
        require(block.timestamp<endTime,"vote expired");
        require(_proposal>=1 && _proposal<=3,"invalid proposal");
        require(!voted[msg.sender],"can not vote again");
        voted[msg.sender] = true;
        if(_proposal==1){
            a++;
        }
        if(_proposal==2){
            b++;
        }
        if(_proposal==3){
            c++;
        }
        emit Voted(msg.sender,_proposal);
    }
}