/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

// File: contracts/bprotocol/scoring/IBTokenScore.sol

pragma solidity 0.5.16;

interface IBTokenScore {
    function start() external view returns (uint);
    function spin() external;

    function getDebtScore(address user, address cToken, uint256 time) external view returns (uint);
    function getCollScore(address user, address cToken, uint256 time) external view returns (uint);

    function getDebtGlobalScore(address cToken, uint256 time) external view returns (uint);
    function getCollGlobalScore(address cToken, uint256 time) external view returns (uint);

    function endDate() external view returns(uint);
}

// File: contracts/bprotocol/connector/JarConnector.sol

pragma solidity 0.5.16;


/**
 * @notice B.Protocol Compound connector contract, which is used by Jar contract
 */
contract JarConnector {

    IBTokenScore public score;
    address[] public cTokens;

    constructor(address[] memory _cTokens, address _score) public {
        score = IBTokenScore(_score);

        cTokens = _cTokens;
    }

    function getUserScore(address user) external view returns (uint) {
        return _getTotalUserScore(user, now);
    }

    // this ignores the comp speed progress, but should be close enough
    function getUserScoreProgressPerSec(address user) external view returns (uint) {
        return _getTotalUserScore(user, now + 1) - _getTotalUserScore(user, now);
    }

    function getGlobalScore() external view returns (uint) {
        return _getTotalGlobalScore(now);
    }

    function _getTotalUserScore(address user, uint time) internal view returns (uint256) {
        uint totalScore = 0;
        for(uint i = 0; i < cTokens.length; i++) {
            uint debtScore = score.getDebtScore(user, cTokens[i], time);
            uint collScore = score.getCollScore(user, cTokens[i], time);
            totalScore = add_(add_(totalScore, debtScore), collScore);
        }
        return totalScore;
    }

    function _getTotalGlobalScore(uint time) internal view returns (uint256) {
        uint totalScore = 0;
        for(uint i = 0; i < cTokens.length; i++) {
            uint debtScore = score.getDebtGlobalScore(cTokens[i], time);
            uint collScore = score.getCollGlobalScore(cTokens[i], time);
            totalScore = add_(add_(totalScore, debtScore), collScore);
        }
        return totalScore;
    }

    function spin() external {
        require(score.endDate() < now, "too-early");
        score.spin();
    }

    function add_(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "overflow");
        return c;
    }
}