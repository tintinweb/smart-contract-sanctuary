/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

/**
https://ropsten.etherscan.io/address/0x6ca347a6be6dcb7b4bf5e1c5df673fe989d61bc9
对用户无限制
用户须支付 0.1 ETH 和并从 1-100 中挑选一个数字
合约所有者决定何时生成随机数(1-100)
选择生成数字的用户获胜（如果这次开奖没有中奖->累积到下一期）
所有奖励将分配给所有赢家
 */

pragma solidity ^0.5.16;

contract LotteryMultiple{
    address owner;
    uint public randNonce = 0;
    // 期号
    uint public idx = 1;
    // 累积的未开奖的金额
    uint public amount = 0 ether;

    enum LotteryState { Accepting, Finished}
    LotteryState state;

    // 当期用户选择的号码
    mapping(uint => mapping (uint => address[])) idxChoices;
    // 每期获奖用户
    mapping (uint => address[]) idxWinners;
    // 每期已领奖的用户
    mapping (uint => mapping(address => bool)) idxGotRewards;
    // 每期每人获奖金额
    mapping (uint => uint) idxPrizes;
    
    
    modifier onlyOwner(){
        require(owner == msg.sender, "only owner can do");
        _;
    }

    constructor() public{
        owner = msg.sender;
        state = LotteryState.Accepting;
    }

    function setState(LotteryState _state) public onlyOwner{
        state = _state;
    }

    function bet(uint8 _num) public payable {
        require(msg.value == 0.1 ether, "send 0.1 ether");
        require(_num > 0 && _num <= 100, "num must be in 1-100");
        require(state == LotteryState.Accepting, "Lottery is closed");
        idxChoices[idx][_num].push(msg.sender);
        amount = amount + msg.value;
    }
 

    function selectWinners() public onlyOwner returns(uint) {
        uint chosen = getRandomNumber(100) + 1;
        address[] memory winners = idxChoices[idx][chosen];
        //进行开奖
        if(winners.length>0){
            uint prize = amount / winners.length;
            idxWinners[idx] = winners;
            idxPrizes[idx] = prize;
            idx ++;
        } else {
            idxPrizes[idx] = 0;
            idx ++;
        }
    }

    function withdrawReward(uint _idx) public {
        require(isWinner(_idx), "you must be a winner");
        require(idxGotRewards[_idx][msg.sender] != true, "you have got your reward");
        idxGotRewards[_idx][msg.sender] = true;
        msg.sender.transfer(idxPrizes[_idx]);
    }

    function isWinner(uint _idx) public view returns(bool) {
        for(uint i = 0; i < idxWinners[_idx].length; i++){
            if(idxWinners[_idx][i] == msg.sender){
                return true;
            } else {
                return false;
            }
        }
        
    }

    function getRandomNumber(uint _limit) public returns(uint){
        uint rand = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % _limit;
        randNonce ++;
        return rand;
    }
}