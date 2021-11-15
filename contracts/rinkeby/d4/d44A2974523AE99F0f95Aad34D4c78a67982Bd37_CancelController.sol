// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CustomWagers.sol"; 
import "./Wagers.sol";
import "./Rewards.sol";
import "./Mevu.sol";

contract CancelController is Ownable {

    CustomWagers private customWagers;
    Wagers private wagers;
    Rewards private rewards;
    Mevu private mevu;

    modifier onlyBettorCustom (bytes32 wagerId) {
        require (msg.sender == customWagers.getMaker(wagerId) || msg.sender == customWagers.getTaker(wagerId));
        _;
    }

    modifier onlyBettorStandard (bytes32 wagerId) {
        require (msg.sender == wagers.getMaker(wagerId) || msg.sender == wagers.getTaker(wagerId));
        _;
    }

    modifier notPaused() {
        require (!mevu.getContractPaused());
        _;
    }

    modifier notSettledCustom(bytes32 wagerId) {
        require (!customWagers.getSettled(wagerId));
        _;           
    }

    modifier notSettledStandard(bytes32 wagerId) {
        require (!wagers.getSettled(wagerId));
        _;           
    }  

    modifier notTakenCustom (bytes32 wagerId) {
        require (customWagers.getTaker(wagerId) == address(0));
        _;
    }

    modifier notTakenStandard (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) == address(0));
        _;
    }

    modifier mustBeTakenCustom (bytes32 wagerId) {
        require (customWagers.getTaker(wagerId) != address(0));
        _;
    }

    modifier mustBeTakenStandard (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) != address(0));
        _;
    }

    function setMevuContract (address payable thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }

    function setCustomWagersContract (address thisAddr) external onlyOwner {
        customWagers = CustomWagers(thisAddr);        
    }

    function setWagersContract (address thisAddr) external onlyOwner {
        wagers = Wagers(thisAddr);        
    }

    function setRewardsContract (address thisAddr) external onlyOwner {
        rewards = Rewards(thisAddr);        
    }

    function cancelWagerStandard (
        bytes32 wagerId,
        bool withdraw      
    ) 
        onlyBettorStandard(wagerId)
        notPaused
        notTakenStandard(wagerId)           
        external 
    {  
        wagers.setSettled(wagerId);                  
        if (withdraw) {
            rewards.subEth(msg.sender, wagers.getOrigValue(wagerId));                
            //msg.sender.transfer (customWagers.getOrigValue(wagerId));
            mevu.transferEth(payable(msg.sender), wagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(msg.sender, wagers.getOrigValue(wagerId));
        }            
    }

     function cancelWagerCustom (
        bytes32 wagerId,
        bool withdraw 
       
    ) 
        onlyBettorCustom(wagerId)
        notPaused      
        notTakenCustom(wagerId)          
        external 
    { 
        customWagers.setSettled(wagerId);                
        if (withdraw) {
            rewards.subEth(msg.sender, customWagers.getOrigValue(wagerId));                
            //msg.sender.transfer (customWagers.getOrigValue(wagerId));
            mevu.transferEth(payable(msg.sender), customWagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(msg.sender, customWagers.getOrigValue(wagerId));
        }            
    }
  
  
    function requestCancelCustom (bytes32 wagerId)
        onlyBettorCustom(wagerId)        
        mustBeTakenCustom(wagerId)
        notSettledCustom(wagerId)
        external
    {
        if (msg.sender == customWagers.getTaker(wagerId)) {            
            customWagers.setTakerCancelRequest(wagerId);
        } else {
            customWagers.setMakerCancelRequest(wagerId);
        }
    }

      
    function requestCancelStandard (bytes32 wagerId)
        onlyBettorStandard(wagerId)
        mustBeTakenStandard(wagerId)       
        notSettledStandard(wagerId)
        external
    {
        if (msg.sender == wagers.getTaker(wagerId)) {            
            wagers.setTakerCancelRequest(wagerId);
        } else {
            wagers.setMakerCancelRequest(wagerId);
        }
    }
  
    function confirmCancelCustom (bytes32 wagerId)
        notSettledCustom(wagerId)
        external 
    {
        if (customWagers.getMakerCancelRequest(wagerId) && customWagers.getTakerCancelRequest(wagerId)) {
           abortWagerCustom(wagerId);
        }
    }

    function confirmCancelStandard (bytes32 wagerId)
        notSettledStandard(wagerId)
        external 
    {
        if (wagers.getMakerCancelRequest(wagerId) && wagers.getTakerCancelRequest(wagerId)) {
           abortWagerStandard(wagerId);
        }
    }

    function abortWagerCustom(bytes32 wagerId) internal {        
        address maker = customWagers.getMaker(wagerId);
        address taker = customWagers.getTaker(wagerId);
        customWagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, customWagers.getOrigValue(wagerId));          
        if (taker != address(0)) {         
            rewards.addUnlockedEth(customWagers.getTaker(wagerId), (customWagers.getWinningValue(wagerId) - customWagers.getOrigValue(wagerId)));
        }             
    }

    function abortWagerStandard(bytes32 wagerId) internal {        
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        wagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));          
        if (taker != address(0)) {         
            rewards.addUnlockedEth(wagers.getTaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        }             
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Wagers is AuthorityGranter {
    using SafeMath for uint256;
    
    struct Wager {
        bytes32 eventId;        
        uint256 origValue;
        uint256 winningValue;        
        uint256 makerChoice;
      
        uint256 odds;
        uint256 makerWinnerVote;
        uint256 takerWinnerVote;
        address payable maker;
        address payable taker;        
        address payable winner;
      
        bool makerCancelRequest;
        bool takerCancelRequest;
        bool locked;
        bool settled; 
        bool takerVoted;       
        bool makerVoted;
    }
 
    mapping (bytes32 => Wager) wagersMap;
    mapping (address => mapping (bytes32 => bool)) recdRefund;  
    
    function makeWager (
        bytes32 wagerId, 
        bytes32 eventId,        
        uint256 origValue,
        uint256 winningValue,        
        uint256 makerChoice,
       
        uint256 odds,
        uint256 makerWinnerVote,
        uint256 takerWinnerVote,
        address payable maker
    )
        external
        onlyAuth             
    {
        Wager memory thisWager = Wager (
            eventId,
            origValue,
            winningValue,
            makerChoice,
            
            odds,
            makerWinnerVote,
            takerWinnerVote,
            maker,
            payable(address(0)),
            payable(address(0)),
            false,
            false,
            false,
            false,
            false,
            false
        );
        wagersMap[wagerId] = thisWager;       
    }    

    function setLocked (bytes32 wagerId) external onlyAuth { wagersMap[wagerId].locked = true; }

    function setSettled (bytes32 wagerId) external onlyAuth { wagersMap[wagerId].settled = true; }

    function setMakerWinVote (bytes32 id, uint256 winnerVote) external onlyAuth { 
        wagersMap[id].makerWinnerVote = winnerVote;
        wagersMap[id].makerVoted = true; 
    }

    function setTakerWinVote (bytes32 id, uint256 winnerVote) external onlyAuth { 
        wagersMap[id].takerWinnerVote = winnerVote;
        wagersMap[id].takerVoted = true;
    }

    function setRefund (address bettor, bytes32 wagerId) external onlyAuth { recdRefund[bettor][wagerId] = true; }

    function setMakerCancelRequest (bytes32 id) external onlyAuth { wagersMap[id].makerCancelRequest = true; }

    function setTakerCancelRequest (bytes32 id) external onlyAuth { wagersMap[id].takerCancelRequest = true; }

    function setTaker (bytes32 wagerId, address payable taker) external onlyAuth { wagersMap[wagerId].taker = taker; }

    function setWinner (bytes32 id, address payable winner) external onlyAuth { wagersMap[id].winner = winner; }

    //function setLoser (bytes32 id, address loser) external onlyAuth { wagersMap[id].loser = loser; }

    function setWinningValue (bytes32 wagerId, uint256 value) external onlyAuth { wagersMap[wagerId].winningValue = value; }

    function getEventId(bytes32 wagerId) external view returns (bytes32) { return wagersMap[wagerId].eventId; }

    function getLocked (bytes32 id) external view returns (bool) { return wagersMap[id].locked; }

    function getSettled (bytes32 id) external view returns (bool) { return wagersMap[id].settled; }

    function getMaker(bytes32 id) external view returns (address payable) { return wagersMap[id].maker; }

    function getTaker(bytes32 id) external view returns (address payable) { return wagersMap[id].taker; }

    function getMakerChoice (bytes32 id) external view returns (uint256) { return wagersMap[id].makerChoice; }

    // function getTakerChoice (bytes32 id) external view returns (uint256) { return wagersMap[id].takerChoice; }

    function getMakerCancelRequest (bytes32 id) external view returns (bool) { return wagersMap[id].makerCancelRequest; }

    function getTakerCancelRequest (bytes32 id) external view returns (bool) { return wagersMap[id].takerCancelRequest; }

    function getMakerWinVote (bytes32 id) external view returns (uint256) { return wagersMap[id].makerWinnerVote; }

    function getRefund (address bettor, bytes32 wagerId) external view returns (bool) { return recdRefund[bettor][wagerId]; }

    function getTakerWinVote (bytes32 id) external view returns (uint256) { return wagersMap[id].takerWinnerVote; }

    function getOdds (bytes32 id) external view returns (uint256) { return wagersMap[id].odds; }

    function getOrigValue (bytes32 id) external view returns (uint256) { return wagersMap[id].origValue; }

    function getWinningValue (bytes32 id) external view returns (uint256) { return wagersMap[id].winningValue; }

    function getWinner (bytes32 id) external view returns (address payable) { return wagersMap[id].winner; }

    //function getLoser (bytes32 id) external view returns (address) { return wagersMap[id].loser; }
    
    function getMakerWinVoted (bytes32 id) external view returns (bool) { return wagersMap[id].makerVoted; }

    function getTakerWinVoted (bytes32 id) external view returns (bool) { return wagersMap[id].takerVoted; }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Rewards is AuthorityGranter {   
    using SafeMath for uint256;

    mapping (address => int) private playerRep;
    mapping (address => int) private oracleRep;  
    mapping (address => uint256) private ethBalance;
    mapping (address => uint256) private mvuBalance;
    mapping (address => uint256) private unlockedEthBalance;
    mapping (address => uint256) private unlockedMvuBalance;  
  
    function subEth(address user, uint256 amount) external onlyAuth { ethBalance[user] -= amount; }

    function subMvu(address user, uint256 amount) external onlyAuth { mvuBalance[user] -= amount; }

    function addEth(address user, uint256 amount) external onlyAuth { ethBalance[user] += amount; }

    function addMvu(address user, uint256 amount) external onlyAuth { mvuBalance[user] += amount; }  

    function subUnlockedMvu(address user, uint256 amount) external onlyAuth { unlockedMvuBalance[user] -= amount; }

    function subUnlockedEth(address user, uint256 amount) external onlyAuth { unlockedEthBalance[user] -= amount; }

    function addUnlockedMvu(address user, uint256 amount) external onlyAuth { unlockedMvuBalance[user] += amount; }

    function addUnlockedEth(address user, uint256 amount) external onlyAuth { unlockedEthBalance[user] += amount; }
    
    function subOracleRep(address oracle, int value) external onlyAuth { oracleRep[oracle] -= value; }

    function subPlayerRep(address player, int value) external onlyAuth { playerRep[player] -= value; }

    function addOracleRep(address oracle, int value) external onlyAuth { oracleRep[oracle] += value; }

    function addPlayerRep(address player, int value) external onlyAuth { playerRep[player] += value; }
      
    function getEthBalance(address user) external view returns (uint256) { return ethBalance[user]; }

    function getMvuBalance(address user) external view returns (uint256) { return mvuBalance[user]; }

    function getUnlockedEthBalance(address user) external view returns (uint256) { return unlockedEthBalance[user]; }

    function getUnlockedMvuBalance(address user) external view returns (uint256) { return unlockedMvuBalance[user]; }

    function getOracleRep (address oracle) external view returns (int) { return oracleRep[oracle]; } 

    function getPlayerRep (address player) external view returns (int) { return playerRep[player]; } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract PoolWagers is AuthorityGranter {
    using SafeMath for uint256;

    struct Wager {
        bytes32 eventId;        
        uint256 origValue;             
        uint256 makerChoice;       
        address maker;        
        bool settled;        
    }
 
    mapping (bytes32 => Wager) wagersMap;
    mapping (address => mapping (bytes32 => bool)) recdRefund;  
    
    function makeWager (
            bytes32 wagerId, 
            bytes32 eventId,        
            uint256 origValue,       
            uint256 makerChoice,     
            address maker
        )
            external
            onlyAuth             
        {
            Wager memory thisWager = Wager (
                eventId,
                origValue,                                       
                makerChoice,                                      
                maker,                                         
                false
            );

            wagersMap[wagerId] = thisWager;
    }    

   
    function setSettled (bytes32 wagerId) external onlyAuth { wagersMap[wagerId].settled = true; }   

    function setRefund (address bettor, bytes32 wagerId) external onlyAuth { recdRefund[bettor][wagerId] = true; }  
  
    function getEventId(bytes32 wagerId) external view returns (bytes32) { return wagersMap[wagerId].eventId; }

    function getSettled (bytes32 id) external view returns (bool) { return wagersMap[id].settled; }

    function getMaker(bytes32 id) external view returns (address) { return wagersMap[id].maker; }  

    function getMakerChoice (bytes32 id) external view returns (uint256) { return wagersMap[id].makerChoice; }    

    function getRefund (address bettor, bytes32 wagerId) external view returns (bool) { return recdRefund[bettor][wagerId]; }
   
    function getOrigValue (bytes32 id) external view returns (uint256) { return wagersMap[id].origValue; }
 

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AuthorityGranter.sol";
import './Events.sol';

contract Oracles is AuthorityGranter {  

    Events events;

    struct OracleStruct { 
        bytes32 eventId;
        uint mvuStake;        
        uint winnerVote;
        bool paid;
    }

    struct EventStruct {
        uint oracleVotes;
        uint totalOracleStake;   
        // uint votesForOne;
        // uint votesForTwo;
        // uint votesForThree;
        uint[] votes;
        // uint stakeForOne;
        // uint stakeForTwo;
        // uint stakeForThree;
        uint[] stakes;
        uint currentWinner;
        mapping (address => uint) oracleStakes;
        address[] oracles;  
       
        bool threshold;
    }

    uint private oracleServiceFee = 3; //Percent
    mapping (address => mapping(bytes32 => bool)) private rewardClaimed;
    mapping (address => mapping(bytes32 => bool)) private refundClaimed;
    mapping (address => mapping(bytes32 => bool)) private alreadyRegistered;    
    mapping (address => mapping (bytes32 => OracleStruct)) private oracleStructs; 
    mapping (bytes32 => EventStruct) private eventStructs;   
    mapping (address => bytes32) private lastEventOraclized;    
    address[] private oracleList; // List of people who have ever registered as an oracle    
    address[] private correctOracles;
    bytes32[] private correctStructs;

    function setEventsContract (address thisAddress) external onlyOwner {
        events = Events(thisAddress);
    }    

    function removeOracle (address oracle, bytes32 eventId) external onlyAuth {
        OracleStruct memory thisOracle;
        bytes32 empty;         
        thisOracle = OracleStruct (empty,0,0, false);               
        oracleStructs[oracle][eventId] = thisOracle;    
    }

    function addOracle (address oracle, bytes32 eventId, uint mvuStake, uint winnerVote, uint minOracleNum) external onlyAuth {
        uint[] memory newVotes = eventStructs[eventId].votes;
        uint[] memory newStakes = eventStructs[eventId].stakes;
        uint numOutcomes = events.getNumOutcomes(eventId) + 1; //because numTeams + 1 means winner could not be decided. A tie is included as a team.
        if (newVotes.length == 0) {
            newVotes = new uint[](numOutcomes); 
            newStakes = new uint[](numOutcomes);   
            for (uint i = 0; i < numOutcomes; i++){
                if (i == winnerVote) {
                    newVotes[i] = 1;
                    newStakes[i] = mvuStake;
                } else {
                    newVotes[i] = 0;
                    newStakes[i] = 0;
                }
            }                    
        } else {
            newVotes[winnerVote] += 1;
            newStakes[winnerVote] += mvuStake;
        }

        OracleStruct memory thisOracle; 
        thisOracle = OracleStruct (eventId, mvuStake, winnerVote, false);      
        oracleStructs[oracle][eventId] = thisOracle;
        // if (winnerVote == 1) {
        //     eventStructs[eventId].votesForOne ++;
        //     eventStructs[eventId].stakeForOne += mvuStake; 
        // }
        // if (winnerVote == 2) {
        //     eventStructs[eventId].votesForTwo ++;
        //     eventStructs[eventId].stakeForTwo += mvuStake; 
        // }
        // if (winnerVote == 3) {
        //     eventStructs[eventId].votesForThree ++;
        //     eventStructs[eventId].stakeForThree += mvuStake; 
        // }
        eventStructs[eventId].votes = newVotes;
        eventStructs[eventId].stakes = newStakes;

        eventStructs[eventId].oracleStakes[oracle] = mvuStake;
        eventStructs[eventId].totalOracleStake += mvuStake;
        eventStructs[eventId].oracleVotes += 1;
        setCurrentWinner(eventId, winnerVote); 

        if (eventStructs[eventId].oracleVotes == minOracleNum) {
            eventStructs[eventId].threshold = true;
            events.setThreshold(eventId);
        }    
    } 

    function setCurrentWinner (bytes32 eventId, uint outcomeJustVotedFor) internal {
        uint currentWinner = eventStructs[eventId].currentWinner;
        // if  (eventStructs[eventId].votesForOne == eventStructs[eventId].votesForTwo) {
        //     eventStructs[eventId].currentWinner = 3;
        //     events.setCurrentWinner(eventId, 3);
        // }
        // if  (eventStructs[eventId].votesForOne > eventStructs[eventId].votesForTwo) {
        //     eventStructs[eventId].currentWinner = 1;
        //     events.setCurrentWinner(eventId, 1);
        // }
        // if  (eventStructs[eventId].votesForTwo > eventStructs[eventId].votesForOne) {
        //     eventStructs[eventId].currentWinner = 2;
        //     events.setCurrentWinner(eventId, 2);
        // }
        // if  (eventStructs[eventId].votesForThree > eventStructs[eventId].votesForOne  &&  eventStructs[eventId].votesForThree > eventStructs[eventId].votesForTwo) {
        //     eventStructs[eventId].currentWinner = 3;
        //     events.setCurrentWinner(eventId, 3);
        // }
        if (currentWinner != outcomeJustVotedFor) {
            if (eventStructs[eventId].votes[outcomeJustVotedFor] > eventStructs[eventId].votes[currentWinner]){
                eventStructs[eventId].currentWinner = outcomeJustVotedFor;
                events.setCurrentWinner(eventId, outcomeJustVotedFor);
            }
        }


    } 


    function addToOracleList (address oracle) external onlyAuth { oracleList.push(oracle); } 

    function setPaid (address oracle, bytes32 eventId) external onlyAuth { oracleStructs[oracle][eventId].paid = true; }  

    function setLastEventOraclized (address oracle, bytes32 eventId) external onlyAuth { lastEventOraclized[oracle] = eventId; }

    function setRefunded (address oracle, bytes32 eventId) external onlyAuth { refundClaimed[oracle][eventId] = true; }

    function setRegistered (address oracle, bytes32 eventId) external onlyAuth { alreadyRegistered[oracle][eventId] = true; }

    function getCurrentWinner (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].currentWinner; } 

    function getRegistered (address oracle, bytes32 eventId) external view returns (bool) { return alreadyRegistered[oracle][eventId]; }

    function getWinnerVote(bytes32 eventId, address oracle) external view returns (uint) { return oracleStructs[oracle][eventId].winnerVote; }

    function getPaid (bytes32 eventId, address oracle) external view returns (bool) { return oracleStructs[oracle][eventId].paid; }

    function getRefunded (bytes32 eventId, address oracle) external view returns (bool) { return refundClaimed[oracle][eventId]; }

    // function getVotesForOne (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForOne; }

    // function getVotesForTwo (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForTwo; }    

    // function getVotesForThree (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForThree; } 

    function getVotesForOutcome (bytes32 eventId, uint outcome) external view returns (uint) { return eventStructs[eventId].votes[outcome]; }

    // function getStakeForOne (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForOne; }

    // function getStakeForTwo (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForTwo; } 

    // function getStakeForThree (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForThree; }  

    function getStakeForOutcome (bytes32 eventId, uint outcome) external view returns (uint) { return eventStructs[eventId].stakes[outcome]; }

    function getMvuStake (bytes32 eventId, address oracle) external view returns (uint) { return oracleStructs[oracle][eventId].mvuStake; }
   
    function getEventOraclesLength (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].oracles.length; }
    
    function getOracleVotesNum (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].oracleVotes; }   

    function getTotalOracleStake (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].totalOracleStake; }

    function getThreshold (bytes32 eventId) external view returns (bool) { return eventStructs[eventId].threshold; } 
 
    function getOracleListLength() external  view returns (uint) { return oracleList.length; }

    function getOracleListAt (uint index) external view returns (address) { return oracleList[index]; }

    function getLastEventOraclized (address oracle) external view returns (bytes32) { return lastEventOraclized[oracle]; }  


//         function subTotalOracleStake (bytes32 eventId, uint amount) external onlyAuth {
//         standardEvents[eventId].totalOracleStake -= amount;
//         standardEvents[eventId].oracleVotes -= 1;
//     }

//     function removeOracleFromEvent (bytes32 eventId, uint oracle) external onlyAuth {
//         standardEvents[eventId].oracles[oracle] = standardEvents[eventId].oracles[standardEvents[eventId].oracles.length - 1];
//         delete standardEvents[eventId].oracles[standardEvents[eventId].oracles.length - 1];
//     }


//   function setOracleStakeAt (bytes32 eventId, address oracle, uint stake) onlyAuth {
//         standardEvents[eventId].oracleStakes[oracle] = stake;
//     }

    function checkOracleStatus (address oracle, bytes32 eventId) external view returns (bool) {
        if (eventStructs[eventId].oracleStakes[oracle] == 0) {
            return false;
        } else {
            return true;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import '../zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

/**
 * @title MvuToken
 * @dev Mintable ERC20 Token which also controls a one-time bet contract, token transfers locked until sale ends.
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract MvuToken is ERC20, Ownable { //  is ERC20, Ownable
    bool mintAble = true;
    uint256 public maxSupply = 10**9 * 10**18;
    event TokensMade(address indexed to, uint amount);   

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(_msgSender(), maxSupply);
        emit TokensMade(msg.sender, maxSupply);      

    }

    modifier canMint() {
        require (mintAble, "You cannot mint");
        _;
    }
    
    function setMintAble (bool _mintAble) onlyOwner external {
        mintAble = _mintAble;
    }

    function mint(address _to, uint _amount) onlyOwner canMint external {
        super._mint(_to, _amount);
    } 

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";
//import "../ethereum-api/oraclizeAPI.sol";
import "./Events.sol";
import "./Admin.sol";
import "./Wagers.sol";
import "./PoolWagers.sol";
import "./Rewards.sol";
import "./Oracles.sol";
import "./MvuToken.sol";

contract Mevu is AuthorityGranter {//, usingOraclize {

    address payable private mevuWallet;
    Events private events;
    Admin private admin;
    Oracles private oracles;
    Rewards private rewards;
    MvuToken private mvuToken;
    Wagers private wagers;
    PoolWagers private poolWagers;

    bool public contractPaused = false;
    bool private randomNumRequired = false;
    int private lastIteratedIndex = -1;
    uint256 public mevuBalance = 0;
    uint256 public lotteryBalance = 0;

    uint256 private oracleServiceFee = 3; //Percent

    uint256 public nextMonth;
    uint256 public lastMonth;
    uint256 private monthSeconds = 2592000;
    uint256 public playerFunds;

    mapping (bytes32 => bool) private validIds;
    mapping (address => bool) private abandoned;

    mapping (address => uint256) private lastLotteryEntryTimes;
    address payable[] private lotteryEntrants;


    event NewOraclizeQuery (string description);
    event OraclizeQueryResponse (string result);
    event LotteryPotIncreased(uint256 addedAmount);
    event ReceivedRandomNumber(uint256 number);
    event OracleEnteredLottery(address entrant);
    event Aborted (bytes32 wagerId);

    modifier notPaused() {
        require (!contractPaused, "Contract paused");
        _;
    }

    modifier onlyPaused() {
        require (contractPaused, "Contract unpaused");
        _;
    }

    modifier onlyBettor (bytes32 wagerId) {
        require (msg.sender == wagers.getMaker(wagerId) || msg.sender == wagers.getTaker(wagerId));
        _;
    }

    modifier onlyPoolBettor (bytes32 wagerId) {
        require (msg.sender == poolWagers.getMaker(wagerId));
        _;
    }

    // Constructor
    constructor () payable {
       // OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        lastMonth = 1; // Last entries default to 0, set the last month to 1 to allow people to enter the first lottery
        nextMonth = block.timestamp + monthSeconds;
        mevuWallet = payable(msg.sender);
    }

    receive () payable external {}

    function setEventsContract (address thisAddr) external onlyOwner { events = Events(thisAddr); }

    function setOraclesContract (address thisAddr) external onlyOwner { oracles = Oracles(thisAddr); }

    function setRewardsContract   (address thisAddr) external onlyOwner { rewards = Rewards(thisAddr); }

    function setAdminContract (address thisAddr) external onlyOwner { admin = Admin(thisAddr); }

    function setWagersContract (address thisAddr) external onlyOwner { wagers = Wagers(thisAddr); }

    function setPoolWagersContract (address thisAddr) external onlyOwner { poolWagers = PoolWagers(thisAddr); }

    function setMvuTokenContract (address thisAddr) external onlyOwner { mvuToken = MvuToken(thisAddr); }

    function setMevuWallet (address payable newAddress) external onlyOwner {
        mevuWallet = newAddress;
    }

    function abandonContract() external onlyPaused {
        require(!abandoned[msg.sender]);
        abandoned[msg.sender] = true;
        uint256 ethBalance =  rewards.getEthBalance(msg.sender);
        uint256 mvuBalance = rewards.getMvuBalance(msg.sender);
        playerFunds -= ethBalance;
        if (ethBalance > 0) {
            address payable _sender = payable(msg.sender);
            _sender.transfer(ethBalance);
        }
        if (mvuBalance > 0) {
            mvuToken.transfer(msg.sender, mvuBalance);
        }
    }

    function getLotteryPot() external view returns (uint256) {
        return lotteryBalance;
    }

    function getLotteryEntrantCount() external view returns (uint256) {
        return lotteryEntrants.length;
    }

    function enterLottery() external returns (bool) {
        require(allowedToWin(msg.sender));
        // Users may not enter more than once
        require(lastLotteryEntryTimes[msg.sender] < lastMonth);

        // Keep track of most recent entry to prevent multiple entries
        lastLotteryEntryTimes[msg.sender] = block.timestamp;
        lotteryEntrants.push(payable(msg.sender));

        emit OracleEnteredLottery(msg.sender);

        return true;
    }

  
    // function runLottery() {
    //     require(block.timestamp > nextMonth);
    //     require(lotteryEntrants.length > 0);
    //     bytes32 queryId = oraclize_query("WolframAlpha", strConcat("random number between 0 and ", uint2str(lotteryEntrants.length - 1)));
    //                     //oraclize_newRandomDSQuery(/* Delay */ 0, /* Random Bytes */ 7, /* Callback Gas */ admin.getCallbackGasLimit());
    //     emit NewOraclizeQuery("Getting random number for picking the lottery winner");
    //     validIds[queryId] = true;
    // }

    // function __callback (bytes32 _queryId, string _result) public {
    //     emit OraclizeQueryResponse(_result);
    //     require(validIds[_queryId]);
    //     require(msg.sender == oraclize_cbAddress());

    //     // Invalidate the query ID so it cannot be reused
    //     validIds[_queryId] = false;

    //     uint256 maxRange = lotteryEntrants.length; // The max number should be no more than the number of entrants - 1
    //     uint256 randomNumber = parseInt(_result) % maxRange;
    //     emit ReceivedRandomNumber(randomNumber);

    //     payoutLottery(randomNumber);
    // }

    /** @dev Pays out the monthly lottery balance to a random oracle.
      */
    function payoutLottery(uint256 winnerIndex) notPaused internal {
        address payable potentialWinner = lotteryEntrants[winnerIndex];
        if (allowedToWin(potentialWinner)) {
            uint256 thisWin = lotteryBalance;
            delete lotteryEntrants;
            
            addMonth();
            lotteryBalance = 0;
            potentialWinner.transfer(thisWin);
        } else {
            // Winner is no longer allowed to win
            // Swap winner with last entrant and then decrease the size of the list (don't need to actually retain old entrant)
            lotteryEntrants[winnerIndex] = lotteryEntrants[lotteryEntrants.length - 1];

            delete lotteryEntrants[lotteryEntrants.length - 1];
            // lotteryEntrants.length = lotteryEntrants.length - 1;
            require(oracles.getOracleListLength() > 0);
            //runLottery();
        }
    }

    function allowedToWin (address potentialWinner) internal view returns (bool) {
        return mvuToken.balanceOf(potentialWinner) > 0
        && block.timestamp - events.getEndTime(oracles.getLastEventOraclized(potentialWinner)) < admin.getMaxOracleInterval()
        && rewards.getOracleRep(potentialWinner) > 0
        && rewards.getPlayerRep(potentialWinner) >= 0;
    }

    // Players should call this when an event has been cancelled after they have made a wager
    function playerRefund (bytes32 wagerId) external  onlyBettor(wagerId) {
        require (events.getCancelled(wagers.getEventId(wagerId)));
        require (!wagers.getRefund(msg.sender, wagerId));
        wagers.setRefund(msg.sender, wagerId);
        address maker = wagers.getMaker(wagerId);
        wagers.setSettled(wagerId);
        if(msg.sender == maker) {
            rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));
        } else {
            rewards.addUnlockedEth(wagers.getTaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        }
    }

      // Players should call this when an event has been cancelled after they have made a poolwager
    function poolPlayerRefund (bytes32 wagerId) external  onlyPoolBettor(wagerId) {
        require (events.getCancelled(poolWagers.getEventId(wagerId)));
        require (!poolWagers.getRefund(msg.sender, wagerId));
        poolWagers.setRefund(msg.sender, wagerId);
        address maker = poolWagers.getMaker(wagerId);
        poolWagers.setSettled(wagerId);
       
        rewards.addUnlockedEth(maker, poolWagers.getOrigValue(wagerId));
      
    }



    function pauseContract()
    external
    onlyOwner
    {
        contractPaused = true;
    }

    // function restartContract(uint256 secondsFromNow)
    //     external
    //     onlyOwner
    //     payable
    // {
    //     contractPaused = false;
    //     //lastIteratedIndex = int(events.getActiveEventsLength()-1);
    //     NewOraclizeQuery("Starting contract!");
    //     bytes32 queryId = oraclize_query(secondsFromNow, "URL", "", admin.getCallbackGasLimit());
    //     validIds[queryId] = true;
    // }

    function mevuWithdraw (uint256 amount) external onlyOwner {
        require(mevuBalance >= amount);
        mevuBalance -= amount;
        mevuWallet.transfer(amount);
    }


    function withdraw(
        uint256 eth
    )
    notPaused
    external
    {
        require (rewards.getUnlockedEthBalance(msg.sender) >= eth);
        rewards.subUnlockedEth(msg.sender, eth);
        rewards.subEth(msg.sender, eth);
        //playerFunds -= eth;
        payable(msg.sender).transfer(eth);
    }

    function addMevuBalance (uint256 amount) external onlyAuth { mevuBalance += amount; }

    // function addEventToIterator () external onlyAuth {
    //     lastIteratedIndex++;
    // }

    function addLotteryBalance (uint256 amount) external onlyAuth {
        lotteryBalance += amount;
        emit LotteryPotIncreased(amount);
    }

    function addToPlayerFunds (uint256 amount) external onlyAuth { playerFunds += amount; }

    function subFromPlayerFunds (uint256 amount) external onlyAuth { playerFunds -= amount; }

    function transferEth (address payable recipient, uint256 amount) external onlyAuth { recipient.transfer(amount); }

    function getContractPaused() external view returns (bool) { return contractPaused; }

    function getOracleFee () external view returns (uint256) { return oracleServiceFee; }

    function transferTokensToMevu (address payable oracle, uint256 mvuStake) internal { mvuToken.transferFrom(oracle, address(this), mvuStake); }

    function transferTokensFromMevu (address oracle, uint256 mvuStake) external onlyAuth { mvuToken.transfer(oracle, mvuStake); }

    function addMonth () internal {
        lastMonth = nextMonth;
        nextMonth += monthSeconds;
    }

    function getNextMonth () internal view returns (uint256) { return nextMonth; }

    function uintToBytes(uint256 v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {    
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
    /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
      *  been cancelled, refunds all eth.
      *  @param wagerId bytes32 wagerId of the wager to abort.
      */
    function abortWager(bytes32 wagerId) onlyBettor(wagerId) external {

        require (events.getCancelled(wagers.getEventId(wagerId)));

        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        wagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));

        if (taker != address(0)) {
            rewards.addUnlockedEth(taker, (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        }
        emit Aborted(wagerId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";
import "./Oracles.sol";
import "./Admin.sol";
import "./Mevu.sol";

contract Events is AuthorityGranter {

    Admin private admin;
    Oracles private oracles;    
    Mevu private mevu;

    event EventVoteReady(bytes32 eventId);
    event EventCancelled(bytes32 eventId);

    struct StandardWagerEvent {         
        bytes32[] teams;
        bool drawPossible;
        uint256 startTime; // Unix timestamp
        uint256 duration; // Seconds
        uint256 numWagers;
        uint256 totalAmountBet;
        uint256[] totalAmountBetForTeam;
        uint256 totalAmountResolvedWithoutOracles;
        uint256 currentWinner;
        uint256 winner;
        uint256 makerBond;           
        uint256 activeEventIndex;        
        address payable maker;
        bytes32[] wagers;  
      
        bool cancelled;
        bool threshold;
      
    }
   
    
    mapping (bytes32 => StandardWagerEvent) private standardEvents;
    mapping (bytes32 => bool) private activeEventsMapping;
    bytes32[] private emptyBytes32Array;
    bytes32[] public activeEvents;
    uint256[] public emptyUintArray;
    uint256 public eventsCount;

    function setOraclesContract (address thisAddr) external onlyOwner {
        oracles = Oracles(thisAddr);
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }

    function setMevuContract (address payable thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }     
       

    /** @dev Creates a new Standard event struct for users to bet on and adds it to the standardEvents mapping.
   
      * @param startTime The timestamp of when the event starts
      * @param duration The length of the event in seconds.     
   
      */
    function makeStandardEvent(
        bytes32 id,        
        uint256 startTime,
        uint256 duration,
        bytes32[] calldata teams,
        bool drawPossible,
        uint256 bondValue,
        address payable maker
     
    )
        external
        onlyAuth            
    {        
        StandardWagerEvent memory thisEvent;
        uint256[] storage betsForArray = emptyUintArray;
        for (uint256 p = 0; p < teams.length; p++) {
            betsForArray.push(0);            
        }
        thisEvent = StandardWagerEvent(                                        
            teams,
            drawPossible,
            startTime,
            duration,
            0,
            0,
            betsForArray,                                   
            0,
            0,
            0,
            bondValue,                                                                                                              
            activeEvents.length,
            maker,  
            emptyBytes32Array,                                                                                                            
            false,
            false
        );
        standardEvents[id] = thisEvent;
        eventsCount++;
        activeEvents.push(id);
        activeEventsMapping[id] = true;
        //mevu.addEventToIterator();     
    }

    function addResolvedWager (bytes32 eventId, uint256 value) external onlyAuth {
        standardEvents[eventId].totalAmountResolvedWithoutOracles += value;
    }

    // function determineEventStage (bytes32 thisEventId, uint256 lastIndex) external onlyAuth {        
    //     uint256 eventEndTime = getStart(thisEventId) + getDuration(thisEventId);
    //     if (block.timestamp > eventEndTime){
    //         // Event is over
    //         if (getVoteReady(thisEventId) == false){
    //             makeVoteReady(thisEventId);
    //             EventVoteReady(thisEventId);
    //         } else {
    //             // Go through next active event in array and finalize winners with voteReady events
    //             decideWinner(thisEventId);
    //             setLocked(thisEventId);
    //             removeEventFromActive(thisEventId);
    //         } 
    //     }
    // }

    function finalizeEvent(bytes32 eventId) external onlyAuth {
        decideWinner(eventId);      
        removeEventFromActive(eventId);
    }

    function decideWinner (bytes32 eventId) internal {      
        // uint256 teamOneCount = oracles.getVotesForOne(eventId);
        // uint256 teamTwoCount = oracles.getVotesForTwo(eventId);
        // uint256 tieCount = oracles.getVotesForThree(eventId);    
        // if (teamOneCount > teamTwoCount && teamOneCount > tieCount){
        //    setWinner(eventId, 1);
        // } else {
        //     if (teamTwoCount > teamOneCount && teamTwoCount > tieCount){
        //     setWinner(eventId, 2);
        //     } else {
        //         if (tieCount > teamTwoCount && tieCount > teamOneCount){
        //             setWinner(eventId, 3);// Tie
        //         } else {
        //             setWinner(eventId, 4); // No clear winner
        //         }
        //     }
        // }
        // if (oracles.getOracleVotesNum(eventId) < admin.getMinOracleNum(eventId)){
        //     setWinner(eventId, 4); // No clear winner
        // }

        if (oracles.getThreshold(eventId)) {
            setWinner(eventId, oracles.getCurrentWinner(eventId));

        } else {
            setWinner(eventId, standardEvents[eventId].teams.length); // No clear winner
        }
    }     


    function removeEventFromActive (bytes32 eventId) internal { 
        uint256 indexToDelete = standardEvents[eventId].activeEventIndex;
        uint256 lastItem = activeEvents.length - 1;
        activeEvents[indexToDelete] = activeEvents[lastItem]; // Write over item to delete with last item
        standardEvents[activeEvents[lastItem]].activeEventIndex = indexToDelete; //Point what was the last item to its new spot in array      
        // activeEvents.length -- ; // Delete what is now duplicate entry in last spot
        delete activeEvents[activeEvents.length-1];

        activeEventsMapping[eventId] = false;
    }

    // function removeWager (bytes32 eventId, uint256 value, uint256 team) external onlyAuth {
    //     standardEvents[eventId].numWagers --;
    //     standardEvents[eventId].totalAmountBet[team] -= value;
    // }   

    function addWagerForTeam(bytes32 eventId, uint256 value, uint256 team) external onlyAuth {      
        standardEvents[eventId].numWagers ++;
        standardEvents[eventId].totalAmountBet += value;
        standardEvents[eventId].totalAmountBetForTeam[team] += value;
    }

    function addWager(bytes32 eventId, uint256 value) external onlyAuth {      
        standardEvents[eventId].numWagers ++;
        standardEvents[eventId].totalAmountBet += value;
    }

    function setCurrentWinner(bytes32 eventId, uint256 newWinner) external onlyAuth { standardEvents[eventId].currentWinner = newWinner; }

    function setCancelled(bytes32 eventId) external onlyAuth { 
        standardEvents[eventId].cancelled = true;
        removeEventFromActive(eventId);
        emit EventCancelled(eventId);
    }

    function setWinner (bytes32 eventId, uint256 winner) public onlyAuth { standardEvents[eventId].winner = winner; }

    function setThreshold (bytes32 eventId) external onlyAuth { standardEvents[eventId].threshold = true; }

    function getActive(bytes32 id) external view returns (bool) { return activeEventsMapping[id]; }  
  
    function getActiveEventId (uint256 i) external view returns (bytes32) { return activeEvents[i]; }

    function getActiveEventsLength () external view returns (uint256) { return activeEvents.length; } 

    function getStandardEventCount () external view returns (uint256) { return eventsCount; }   

    function getTotalAmountBet (bytes32 eventId) external view returns (uint256) { return standardEvents[eventId].totalAmountBet; }

    function getTotalAmountBetForTeam (bytes32 eventId, uint256 team) external view returns (uint256) { return standardEvents[eventId].totalAmountBetForTeam[team]; }

    function getTotalAmountResolvedWithoutOracles (bytes32 eventId) external view returns (uint256) { return standardEvents[eventId].totalAmountResolvedWithoutOracles; }

    function getCancelled(bytes32 id) external view returns (bool) { return standardEvents[id].cancelled; }

    function getCurrentWinner (bytes32 id) external view returns (uint256) {return standardEvents[id].currentWinner;}

    function getStart (bytes32 id) public view returns (uint256) { return standardEvents[id].startTime; }

    function getDuration (bytes32 id) public view returns (uint256) { return standardEvents[id].duration; }

    function getEndTime (bytes32 id) public view returns (uint256) { return (standardEvents[id].startTime + standardEvents[id].duration); }

    function getLocked(bytes32 id) public view returns (bool) { return (block.timestamp > getEndTime(id) + admin.getOraclePeriod()); }

    function getMaker (bytes32 eventId) external view returns (address payable) { return standardEvents[eventId].maker; }

    function getMakerBond (bytes32 eventId) external view returns (uint256) { return standardEvents[eventId].makerBond; }

    function getNumOutcomes (bytes32 eventId) external view returns (uint256) { return standardEvents[eventId].teams.length; }

    function getTeams (bytes32 eventId) external view returns (bytes32[] memory) { return standardEvents[eventId].teams; }

    function getDrawPossible (bytes32 eventId) external view returns (bool) { return standardEvents[eventId].drawPossible; }

    function getThreshold (bytes32 eventId) external view returns (bool) { return standardEvents[eventId].threshold; }

    function getWinner (bytes32 id) external view returns (uint256) { return (standardEvents[id].threshold ? standardEvents[id].currentWinner : standardEvents[id].winner); }

    function getVoteReady (bytes32 id) public view returns (bool) { return (getEndTime(id) < block.timestamp); }   

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract CustomWagers is AuthorityGranter {
    using SafeMath for uint256;

    struct Wager {
        uint256 endTime;
        uint256 reportingEndTime;            
        uint256 origValue;
        uint256 winningValue;        
        uint256 makerChoice;
        uint256 takerChoice;
        uint256 odds;
        uint256 makerWinnerVote;
        uint256 takerWinnerVote;
        address payable maker;
        address payable taker;
        address payable judge;        
        address payable winner;         
        bool makerCancelRequest;
        bool takerCancelRequest;       
        bool settled;        
    }

    mapping (bytes32 => bool) private cancelled;   
    mapping (bytes32 => Wager) private wagersMap;
    mapping (address => mapping (bytes32 => bool)) private recdRefund;
    mapping  (bytes32 => uint256) private judgesVote;

    
    function makeWager (
        bytes32 wagerId,
        uint256 endTime,
        uint256 reportingEndTime,          
        uint256 origValue,
        uint256 winningValue,        
        uint256 makerChoice,
        uint256 takerChoice,
        uint256 odds,
        uint256 makerWinnerVote,
        uint256 takerWinnerVote,
        address payable maker
        
        )
            external
            onlyAuth             
        {
        Wager memory thisWager = Wager (
            endTime,
            reportingEndTime,
            origValue,
            winningValue,
            makerChoice,
            takerChoice,
            odds,
            makerWinnerVote,
            takerWinnerVote,
            maker,
            payable(address(0)),
            payable(address(0)),
            payable(address(0)),                                       
            false,
            false,                                        
            false
        );
        wagersMap[wagerId] = thisWager;       
    }

    function addJudge (bytes32 wagerId, address payable judge) external onlyAuth {
        wagersMap[wagerId].judge = judge;
    }

    function setCancelled (bytes32 wagerId) external onlyAuth {
        cancelled[wagerId] = true;
    }    

    function setSettled (bytes32 wagerId) external onlyAuth {
        wagersMap[wagerId].settled = true;
    }

    function setMakerWinVote (bytes32 id, uint256 winnerVote) external onlyAuth {
        wagersMap[id].makerWinnerVote = winnerVote;
    }

    function setTakerWinVote (bytes32 id, uint256 winnerVote) external onlyAuth {
        wagersMap[id].takerWinnerVote = winnerVote;
    }

    function setRefund (address bettor, bytes32 wagerId) external onlyAuth {
        recdRefund[bettor][wagerId] = true;
    }

    function setMakerCancelRequest (bytes32 id) external onlyAuth {
        wagersMap[id].makerCancelRequest = true;
    }

    function setTakerCancelRequest (bytes32 id) external onlyAuth {
        wagersMap[id].takerCancelRequest = true;
    }

    function setTaker (bytes32 wagerId, address payable taker) external onlyAuth {
        wagersMap[wagerId].taker = taker;
    }

    function setWinner (bytes32 id, address payable winner) external onlyAuth {
        wagersMap[id].winner = winner;        
    }

    function setJudgesVote (bytes32 id, uint256 vote) external onlyAuth {
        judgesVote[id] = vote;
    }

    // function setLoser (bytes32 id, address loser) external onlyAuth {
    //     wagersMap[id].loser = loser;
    // }

    function setWinningValue (bytes32 wagerId, uint256 value) external onlyAuth {
        wagersMap[wagerId].winningValue = value;
    }

    function getCancelled (bytes32 wagerId) external view returns (bool) {
        return cancelled[wagerId];
    }

    function getEndTime (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].endTime;
    } 

    function getReportingEndTime (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].reportingEndTime;
    }   

    function getLocked (bytes32 id) external view returns (bool) {
        if (wagersMap[id].taker == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function getSettled (bytes32 id) external view returns (bool) {
        return wagersMap[id].settled;
    }

    function getMaker(bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].maker;
    }

    function getTaker(bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].taker;
    }

    function getMakerChoice (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].makerChoice;
    }

    function getTakerChoice (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].takerChoice;
    }

    function getMakerCancelRequest (bytes32 wagerId) external view returns (bool) {
        return wagersMap[wagerId].makerCancelRequest;
    }

    function getTakerCancelRequest (bytes32 wagerId) external view returns (bool) {
        return wagersMap[wagerId].takerCancelRequest;
    }

    function getMakerWinVote (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].makerWinnerVote;
    }
    
    function getTakerWinVote (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].takerWinnerVote;
    }

    function getRefund (address bettor, bytes32 wagerId) external view returns (bool) {
        return recdRefund[bettor][wagerId];
    }    

    function getOdds (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].odds;
    }

    function getOrigValue (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].origValue;
    }

    function getWinningValue (bytes32 wagerId) external view returns (uint256) {
        return wagersMap[wagerId].winningValue;
    }

    function getWinner (bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].winner;
    } 
    
    function getLoser (bytes32 wagerId) external view returns (address payable) {
        address payable winner = wagersMap[wagerId].winner;
        address payable maker = wagersMap[wagerId].maker;
        address payable taker = wagersMap[wagerId].taker;
        if (winner == taker) {
            return maker;
        } else if  (winner == maker) {
            return taker;
        } else {
            return payable(address(0));
        }
    }

    function getJudge (bytes32 wagerId) external view returns (address payable) {
        return wagersMap[wagerId].judge;
    }

    function getJudgesVote (bytes32 wagerId) external view returns (uint256) {
        return judgesVote[wagerId];
    }

   


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthorityGranter is Ownable {

    mapping (address => bool) internal isAuthorized;  

    modifier onlyAuth () {
        require(isAuthorized[msg.sender], "Only authorized sender will be allowed");               
        _;
    }

    function grantAuthority (address nowAuthorized) external onlyOwner {
        require(isAuthorized[nowAuthorized] == false, "Already granted");
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) external onlyOwner {
        require(isAuthorized[unauthorized] == true, "Already unauthorized");
        isAuthorized[unauthorized] = false;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Admin is AuthorityGranter {  
    using SafeMath for uint256;
    
    uint256 private abandonPeriod = 100000;            // give up  
    uint256 private minWagerAmount = 10;               // wager => bet  
    uint256 private callbackInterval = 1;                
    uint256 private minOracleStake = 1;                  
    uint256 private minEventBond = 10000;                
    uint256 private maxOracleInterval= 604800;         // Time in seconds allowed since the last event an oracle service was performed (to win lottery)      
                                                      
    uint256 private oraclePeriod = 1800;               // TIme in seconds the oracles have to report a score before an event can be finalized      
                                                      
    uint256 private eventMakerFinalizeCushion = 3600;  // TIme an event creator has after the oracle period ends to finalize the event before their reward can be stolen  
                                                      
    uint256 private eventMakerRewardDivider = 10000;     
    uint256 private callbackGasLimit = 900000;    
    int private oracleRepPenalty = 4;                 
    int private oracleRepReward = 1;                  
    int private playerAgreeRepReward = 1;             
    int private playerDisagreeRepPenalty = 4;         
    
    mapping (bytes32 => uint256) private minOracleNum;

    function setAbandonPeriod(uint256 newPeriod) external onlyAuth { abandonPeriod = newPeriod; }

    function setEventMakerFinalizeCushion(uint256 newCushion) external onlyAuth { eventMakerFinalizeCushion = newCushion; }    

    function setMinEventBond(uint256 newBond) external onlyAuth { minEventBond = newBond; }         

    function setMinOracleStake (uint256 newMin) external onlyAuth { minOracleStake = newMin; }

    function setMinOracleNum (bytes32 eventId, uint256 min) external onlyAuth { minOracleNum[eventId] = min; }

    function setMaxOracleInterval (uint256 max) external onlyAuth { maxOracleInterval = max; }

    function setOraclePeriod (uint256 newPeriod) external onlyAuth { oraclePeriod = newPeriod; }  

    function setOracleRepPenalty (int penalty) external onlyAuth { oracleRepPenalty = penalty; } 

    function setOracleRepReward (int reward) external onlyAuth { oracleRepReward = reward; }

    function setPlayerAgreeRepReward (int reward) external onlyAuth { playerAgreeRepReward = reward; }

    function setPlayerDisagreeRepPenalty (int penalty) external onlyAuth { playerDisagreeRepPenalty = penalty; }  

    function setCallbackGasLimit (uint256 newLimit) external onlyAuth { callbackGasLimit = newLimit; }    
    
  /** @dev Sets a new number for the interval in between callback functions.
    * @param newInterval The new interval between oraclize callbacks.        
    */
    function setCallbackInterval(uint256 newInterval) external onlyAuth { callbackInterval = newInterval; }

  /** @dev Updates the minimum amount of ETH required to make a wager.
    * @param minWager The new required minimum amount of ETH to make a wager.
    */
    function setMinWagerAmount(uint256 minWager) external onlyAuth { minWagerAmount = minWager; }

    function getAbandonPeriod() external view returns (uint256) { return abandonPeriod; } 
    
    function getCallbackGasLimit() external view returns (uint256) { return callbackGasLimit; }  
    
    function getCallbackInterval() external view returns (uint256) { return callbackInterval; }

    function getEventMakerFinalizeCushion() external view returns (uint256) { return eventMakerFinalizeCushion; }

    function getEventMakerRewardDivider() external view returns (uint256) { return eventMakerRewardDivider; }

    function getMaxOracleInterval() external view returns (uint256) { return maxOracleInterval; } 

    function getMinEventBond() external view returns (uint256) { return minEventBond; } 
    
    function getMinOracleNum (bytes32 eventId) external view returns (uint256) { return minOracleNum[eventId]; }

    function getMinOracleStake () external view returns (uint256) { return minOracleStake; }   
    
    function getMinWagerAmount() external view returns (uint256) { return minWagerAmount; }

    function getOraclePeriod() external view returns (uint256) { return oraclePeriod; }
    
    function getOracleRepPenalty () external view returns (int) { return oracleRepPenalty; }

    function getOracleRepReward () external view returns (int) { return oracleRepReward; }

    function getPlayerAgreeRepReward () external view returns (int) { return playerAgreeRepReward; }

    function getPlayerDisagreeRepPenalty () external view returns (int) { return playerDisagreeRepPenalty; }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

