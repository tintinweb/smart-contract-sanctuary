/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity >=0.8;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    event NameChanged(string name, string symbol);

    function decimals() external view returns (uint8);

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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

abstract contract IDraggable {
    
    function getOracle() public virtual returns (address);
    function drag(address buyer, address currency) public virtual;
    function notifyOfferEnded() public virtual;
    function votingPower(address voter) public virtual returns (uint256);
    function totalVotingTokens() public virtual view returns (uint256);
    function notifyVoted(address voter) public virtual;

}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity >=0.8;

import "../IERC20.sol";
import "./IDraggable.sol";
/**
 * @title Acquisition Attempt
 * @author Luzius Meisser, [email protected]
 */

contract Offer {

    uint256 public immutable quorum;                    // Percentage of votes needed to start drag-along process in BPS, i.e. 10'000 = 100%

    IDraggable public immutable token;
    address public immutable buyer;                     // who made the offer
    
    IERC20 public immutable currency;
    uint256 public immutable price;                               // the price offered per share

    enum Vote { NONE, YES, NO }                         // Used internally, represents not voted yet or yes/no vote.
    mapping (address => Vote) private votes;            // Who votes what
    uint256 public yesVotes;                            // total number of yes votes, including external votes
    uint256 public noVotes;                             // total number of no votes, including external votes
    uint256 public noExternal;                          // number of external no votes reported by oracle
    uint256 public yesExternal;                         // number of external yes votes reported by oracle

    uint256 public immutable voteEnd;                             // end of vote period in block time (seconds after 1.1.1970)

    event VotesChanged(uint256 newYesVotes, uint256 newNoVotes);
    event OfferCreated(address indexed buyer, address token, uint256 pricePerShare, address currency);
    event OfferEnded(address indexed buyer, bool success, string message);

    // Not checked here, but buyer should make sure it is well funded from the beginning
    constructor(
        address _buyer,
        address _token,
        uint256 _price,
        address _currency,
        uint256 _quorum,
        uint256 votePeriod
        ) payable {
        buyer = _buyer;
        token = IDraggable(_token);
        currency = IERC20(_currency);
        price = _price;
        quorum = _quorum;
        voteEnd = block.timestamp + votePeriod;
        // License Fee to Aktionariat AG, also ensures that offer is serious.
        // Any circumvention of this license fee payment is a violation of the copyright terms.
        payable(0x29Fe8914e76da5cE2d90De98a64d0055f199d06D).transfer(3 ether);
        emit OfferCreated(_buyer, address(_token), _price, address(_currency));
    }

    function makeCompetingOffer(address betterOffer) public {
        require(msg.sender == address(token));
        Offer better = Offer(betterOffer);
        require(!isAccepted(), "old already accepted");
        require(currency == better.currency() && better.price() > price, "old offer better");
        require(better.isWellFunded(), "not funded");
        kill(false, "replaced");
    }

    function hasExpired() internal view returns (bool) {
        return block.timestamp > voteEnd + 30 days; // buyer has thirty days to complete acquisition after voting ends
    }

    function contest() public {
        if (hasExpired()) {
            kill(false, "expired");
        } else if (isDeclined()) {
            kill(false, "declined");
        } else if (!isWellFunded()) {
            kill(false, "lack of funds");
        }
    }

    function cancel() public {
        require(msg.sender == buyer);
        kill(false, "cancelled");
    }

    function execute() public {
        require(msg.sender == buyer, "not buyer");
        require(isAccepted(), "not accepted");
        uint256 totalPrice = getTotalPrice();
        require(currency.transferFrom(buyer, address(token), totalPrice));
        token.drag(buyer, address(currency));
        kill(true, "success");
    }

    function getTotalPrice() internal view returns (uint256) {
        IERC20 tok = IERC20(address(token));
        return (tok.totalSupply() - tok.balanceOf(buyer)) * price;
    }

    function isWellFunded() public view returns (bool) {
        uint256 buyerBalance = currency.balanceOf(buyer);
        uint256 totalPrice = getTotalPrice();
        return totalPrice <= buyerBalance;
    }

    function isAccepted() public view returns (bool) {
        if (isVotingOpen()) {
            // is it already clear that 75% will vote yes even though the vote is not over yet?
            return yesVotes * 10000  >= quorum * IDraggable(token).totalVotingTokens();
        } else {
            // did 75% of all cast votes say 'yes'?
            return yesVotes * 10000 >= quorum * (yesVotes + noVotes);
        }
    }

    function isDeclined() public view returns (bool) {
        if (isVotingOpen()) {
            // is it already clear that 25% will vote no even though the vote is not over yet?
            uint256 supply = token.totalVotingTokens();
            return (supply - noVotes) * 10000 < quorum * supply;
        } else {
            // did quorum% of all cast votes say 'no'?
            return 10000 * yesVotes < quorum * (yesVotes + noVotes);
        }
    }

    function notifyMoved(address from, address to, uint256 value) public {
        require(msg.sender == address(token));
        if (isVotingOpen()) {
            Vote fromVoting = votes[from];
            Vote toVoting = votes[to];
            update(fromVoting, toVoting, value);
        }
    }

    function update(Vote previousVote, Vote newVote, uint256 votes_) internal {
        if (previousVote != newVote) {
            if (previousVote == Vote.NO) {
                noVotes = noVotes - votes_;
            } else if (previousVote == Vote.YES) {
                yesVotes = yesVotes - votes_;
            }
            if (newVote == Vote.NO) {
                noVotes = noVotes + votes_;
            } else if (newVote == Vote.YES) {
                yesVotes = yesVotes + votes_;
            }
            emit VotesChanged(yesVotes, noVotes);
        }
    }

    function isVotingOpen() public view returns (bool) {
        return block.timestamp <= voteEnd;
    }

    modifier votingOpen() {
        require(isVotingOpen(), "vote ended");
        _;
    }

    /**
     * Function to allow the oracle to report the votes of external votes (e.g. shares tokenized on other blockchains).
     * This functions is idempotent and sets the number of external yes and no votes. So when more votes come in, the
     * oracle should always report the total number of yes and no votes. Abstentions are not counted.
     */
    function reportExternalVotes(uint256 yes, uint256 no) public {
        require(msg.sender == token.getOracle(), "not oracle");
        require(yes + no + IERC20(address(token)).totalSupply() <= token.totalVotingTokens(), "too many votes");
        // adjust total votes taking into account that the oralce might have reported different counts before
        yesVotes = yesVotes - yesExternal + yes;
        noVotes = noVotes - noExternal + no;
        // remember how the oracle voted in case the oracle later reports updated numbers
        yesExternal = yes;
        noExternal = no;
    }

    function voteYes() public {
        vote(Vote.YES);
    }

    function voteNo() public { 
        vote(Vote.NO);
    }

    function vote(Vote newVote) internal votingOpen() {
        Vote previousVote = votes[msg.sender];
        votes[msg.sender] = newVote;
        if(previousVote == Vote.NONE){
            IDraggable(token).notifyVoted(msg.sender);
        }
        update(previousVote, newVote, IDraggable(token).votingPower(msg.sender));
    }

    function hasVotedYes(address voter) public view returns (bool) {
        return votes[voter] == Vote.YES;
    }

    function hasVotedNo(address voter) public view returns (bool) {
        return votes[voter] == Vote.NO;
    }

    function kill(bool success, string memory message) internal {
        IDraggable(token).notifyOfferEnded();
        emit OfferEnded(buyer, success, message);
        selfdestruct(payable(buyer));
    }

}

/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity >=0.8;

import "./Offer.sol";

contract OfferFactory {
    
    event OfferCreated(address contractAddress, string typeName);

    // It must be possible to predict the address of the offer so one can pre-fund the allowance.
    function predict(bytes32 salt, address buyer, address token, uint256 pricePerShare, address currency, uint256 quorum, uint256 votePeriod) public view returns (address) {
        bytes32 initCodeHash = keccak256(abi.encodePacked(type(Offer).creationCode, abi.encode(buyer, token, pricePerShare, currency, quorum, votePeriod)));
        bytes32 hashResult = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCodeHash));
        return address(uint160(uint256(hashResult)));
    }

    // Do not call directly, msg.sender must be the token to be acquired
    function create(bytes32 salt, address buyer, uint256 pricePerShare, address currency, uint256 quorum, uint256 votePeriod) public payable returns (address) {
        Offer offer = new Offer{value: msg.value, salt: salt}(buyer, msg.sender, pricePerShare, currency, quorum, votePeriod);
        return address(offer);
    }
}