/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title PetraAndChrisWeddingContract
 * 
 *       .....           .....
 *   ,ad8PPPP88b,     ,d88PPPP8ba,
 *  d8P"      "Y8b, ,d8P"      "Y8b
 * dP'           "8a8"           `Yd
 * 8(              "              )8
 * I8                             8I
 *  Yb,                         ,dP
 *   "8a,                     ,a8"
 *     "8a,                 ,a8"
 *       "Yba             adP" 
 *         `Y8a         a8P'
 *           `88,     ,88'
 *            "8b   d8"
 *             "8b d8"
 *              `888'
 *                "
 * 
 * @notice this contract was developed on the journey 
 * to the wedding and there was no time for a divorce function
 * so you better stay happily married - otherwise you need to 
 * stop or fork Ethereum's MainNet ;-)
 *
 * I wish you all the best for the time ahead! 
 * 
 * 
 * @author [email protected]
 * 
 * Heart ASCII art by Norman Veilleux and Ryan Harding
 * 
 */
contract PetraAndChrisWeddingContract {

    // optimistic approach - think with these 2 people 
    // we can be optimistic about things
    bool ceremonyCompletedWithSuccess = true; 

    // ceremony starts 30.09.2021 11:30 and last ~20 min
    // adding 20 seconds to have it end on 420
    uint256 ceremonyEndTime = 1632995420;

    // give ligi a maximum 7 hours after the ceremony ended to report a problem
    uint256 lastPossibleTimeForProblemReport = ceremonyEndTime + 420 minutes;
    
    /**
     * @notice should never be called
     * can only be called by ligi in case of ceremony problems
     */
    function reportCeremonyProblem() public {
         // ligi will attend the ceremony and can call this function 
         // if one of them got cold feet or anything else went wrong 
        require(msg.sender == 0x0402c3407dcBD476C3d2Bbd80d1b375144bAF4a2);
        
        require(block.timestamp <= lastPossibleTimeForProblemReport);
 
        // hope we do not reach this point
        ceremonyCompletedWithSuccess = false; 
    }
    
    /**
     * @return whether Chris and Petra are married
     */
    function arePetraAndChrisMarried() public view returns (bool) {
        return (block.timestamp > ceremonyEndTime) && ceremonyCompletedWithSuccess;
    }
}