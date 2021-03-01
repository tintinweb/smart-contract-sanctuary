// SPDX-License-Identifier: UNLICENSED
// https://spdx.org/licenses/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./_Ownable_.sol";
import "./_OpenClose.sol";
import "./_Guest_.sol";

/*
    caution
    compiler    : 0.6.12
    language    : solidity
    evm version : petersburg / homestead ?
    enable optimization 200
*/

contract Lottery is _Ownable_, _OpenClose, _Guest_{
    uint32 public constant version = 20210128;

    // Required function
    receive()   external payable{/* require(msg.data.length == 0); */}
    fallback()  external payable{/* require(msg.data.length == 0); */}
 
    constructor() public {
        _owner = msg.sender;

        $global.accumulationRate   = 70; // 70   : 70%

        // unit : K, 500 => 500 * 1000
        $config[0].guestLimits  =   1;
        $config[1].guestLimits  =   1;
        $config[2].guestLimits  =   1;

        // fix 0.01 ether(10 finney)
        $config[0].slotPrice    = 10 finney;
        $config[1].slotPrice    = 10 finney;
        $config[2].slotPrice    = 10 finney;

        $global.findPage     = 1000;

        // Initialization fresh start
        $STATE memory c;
        $_state[0]             = c;
        $_state[0].progressStep= $PROGRESS.Opened_ReadyToTimeout;  // ReadyToOpen:0 -> set 1
        $_state[0].dateStart   = uint32(block.timestamp);
        $_state[0].turn        = 1;
        $_state[1]             = c;
        $_state[1].progressStep= $PROGRESS.Opened_ReadyToTimeout;  // ReadyToOpen:0 -> set 1
        $_state[1].dateStart   = uint32(block.timestamp);
        $_state[1].turn        = 1;
        $_state[2]             = c;
        $_state[2].progressStep= $PROGRESS.Opened_ReadyToTimeout;  // ReadyToOpen:0 -> set 1
        $_state[2].dateStart   = uint32(block.timestamp);
        $_state[2].turn        = 1;
    }

    function boardState() external view onlyOwner returns(
        uint[3] memory amounts // amount35, amount40, amount45,
        ){
        amounts[0] = $_state[0].fullAmounts / 1 finney;
        amounts[1] = $_state[1].fullAmounts / 1 finney;
        amounts[2] = $_state[2].fullAmounts / 1 finney;
    }

    function boardClosed()external view onlyOwner returns(LASTGAME memory l35, LASTGAME memory l40, LASTGAME memory l45){
        l35 = _lastgame[0];
        l40 = _lastgame[1];
        l45 = _lastgame[2];
    }
    
    struct $PROGRESSES{
        // open/close
        uint24      turn;
        bool        isRunning;
        $PROGRESS   progress;
        // accumulated
        uint        accumulated;
        // guest
        uint        guestLimits;
        uint        guestCounts;
        // timeout
        uint32      timeStart;
        uint32      timeoutUntil;
        // find seek
        uint        seekPosition;
    }
    function lookupProgress() external view onlyOwner returns($PROGRESSES[3] memory progress){
        for(uint8 c = 0; c < 3; c++){
            progress[c].turn            = $_state[c].turn;
            progress[c].progress        = $_state[c].progressStep;
            progress[c].isRunning       = ($_state[c].progressStep == $PROGRESS.Opened_ReadyToTimeout || $_state[c].progressStep == $PROGRESS.Timeout_ReadyToClose);
            progress[c].accumulated     = $_state[c].fullAmounts / 100 * $global.accumulationRate;
            progress[c].guestLimits     = $config[c].guestLimits;
            progress[c].guestCounts     = $guests[c].lists.length;
            progress[c].timeStart       = $_state[c].dateStart;
            progress[c].timeoutUntil    = $_state[c].dateExpiry;
            progress[c].seekPosition    = $seekPosition[c];
        }
    }

    function paymentWaitingList() external view onlyOwner returns(WINNER[] memory waiting, WINNER[] memory withdraw){
        return (_waitingList,_withdrawedList);
    }

    function paymentWithdraw() external onlyOwner{
        require(_waitingList.length > 0);

        WINNER memory winner;
        winner = _waitingList[_waitingList.length - 1];
        
        address self = address(this);
        uint balance = self.balance;
        require(balance > winner.toBePaid);

        //payable(winner.wallet).transfer(winner.toBePaid);
        (bool success, ) = payable(winner.guest.wallet).call{value:winner.toBePaid}("");
        require(success, "Transfer failed.");

        winner.datetime = uint32(block.timestamp);//now
        _waitingList.pop(); // remove last item
        _withdrawedList.push(winner);
    }
    function clearWithdraw() external onlyOwner{
        delete _withdrawedList;
    }

// [ ■■■ private utilities ■■■ 
// ] ■■■ private utilities ■■■ 

// [ ■■■ test code ■■■ 
// ] ■■■ test code ■■■ 

// [ ■■■ deprecated ■■■ 
// ] ■■■ deprecated ■■■ 

} // ] Lottery