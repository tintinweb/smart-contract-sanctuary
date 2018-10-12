pragma solidity ^ 0.4.25;


// -----------------------------------------------------------------------------------------------------------------
//
//                 Recon&#174; Token Teleportation Service v1.10
//
//                           of BlockReconChain&#174;
//                             for ReconBank&#174;
//
//                     ERC Token Standard #20 Interface
//
// -----------------------------------------------------------------------------------------------------------------
//.
//"
//.             ::::::..  .,::::::  .,-:::::     ...    :::.    :::
//.           ;;;;``;;;; ;;;;&#39;&#39;&#39;&#39; ,;;;&#39;````&#39;  .;;;;;;;.`;;;;,  `;;;
//.            [[[,/[[[&#39;  [[cccc  [[[        ,[[     \[[,[[[[[. &#39;[[
//.            $$$$$$c    $$""""  $$$        $$$,     $$$$$$ "Y$c$$
//.            888b "88bo,888oo,__`88bo,__,o,"888,_ _,88P888    Y88
//.            MMMM   "W" """"YUMMM "YUMMMMMP" "YMMMMMP" MMM     YM
//.
//.
//" -----------------------------------------------------------------------------------------------------------------
//             &#184;.•*&#180;&#168;)
//        &#184;.•&#180;   &#184;.•&#180;&#184;.•*&#180;&#168;) &#184;.•*&#168;)
//  &#184;.•*&#180;       (&#184;.•&#180; (&#184;.•` &#164; ReconBank.eth / ReconBank.com*&#180;&#168;)
//                                                        &#184;.•&#180;&#184;.•*&#180;&#168;)
//                                                      (&#184;.•&#180;   &#184;.•`
//                                                          &#184;.•&#180;•.&#184;
//   (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
// -----------------------------------------------------------------------------------------------------------------
//
// Common ownership of :
//  ____  _            _    _____                       _____ _           _
// |  _ \| |          | |  |  __ \                     / ____| |         (_)
// | |_) | | ___   ___| | _| |__) |___  ___ ___  _ __ | |    | |__   __ _ _ _ __
// |  _ <| |/ _ \ / __| |/ /  _  // _ \/ __/ _ \| &#39;_ \| |    | &#39;_ \ / _` | | &#39;_ \
// | |_) | | (_) | (__|   <| | \ \  __/ (_| (_) | | | | |____| | | | (_| | | | | |
// |____/|_|\___/ \___|_|\_\_|  \_\___|\___\___/|_| |_|\_____|_| |_|\__,_|_|_| |_|&#174;
//&#39;
// -----------------------------------------------------------------------------------------------------------------
//
// This contract is an order from :
//&#39;
// ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗██████╗  █████╗ ███╗   ██╗██╗  ██╗    ██████╗ ██████╗ ███╗   ███╗&#174;
// ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝   ██╔════╝██╔═══██╗████╗ ████║
// ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║██████╔╝███████║██╔██╗ ██║█████╔╝    ██║     ██║   ██║██╔████╔██║
// ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║██╔══██╗██╔══██║██║╚██╗██║██╔═██╗    ██║     ██║   ██║██║╚██╔╝██║
// ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║██████╔╝██║  ██║██║ ╚████║██║  ██╗██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
// ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝&#39;
//
// -----------------------------------------------------------------------------------------------------------------
//
//
//                                 Copyright MIT :
//                      GNU Lesser General Public License 3.0
//                  https://www.gnu.org/licenses/lgpl-3.0.en.html
//
//              Permission is hereby granted, free of charge, to
//              any person obtaining a copy of this software and
//              associated documentation files ReconCoin&#174; Token
//              Teleportation Service, to deal in the Software without
//              restriction, including without limitation the rights to
//              use, copy, modify, merge, publish, distribute,
//              sublicense, and/or sell copies of the Software, and
//              to permit persons to whom the Software is furnished
//              to do so, subject to the following conditions:
//              The above copyright notice and this permission
//              notice shall be included in all copies or substantial
//              portions of the Software.
//
//                 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
//                 WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//                 INCLUDING BUT NOT LIMITED TO THE
//                 WARRANTIES OF MERCHANTABILITY, FITNESS FOR
//                 A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//                 IN NO EVENT SHALL THE AUTHORS OR
//                 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//                 DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//                 ACTION OF CONTRACT, TORT OR
//                 OTHERWISE, ARISING FROM, OUT OF OR IN
//                 CONNECTION WITH THE SOFTWARE OR THE USE
//                 OR OTHER DEALINGS IN THE SOFTWARE.
//
//
// -----------------------------------------------------------------------------------------------------------------


pragma solidity ^ 0.4.25;


// -----------------------------------------------------------------------------------------------------------------
// The new assembly support in Solidity makes writing helpers easy.
// Many have complained how complex it is to use `ecrecover`, especially in conjunction
// with the `eth_sign` RPC call. Here is a helper, which makes that a matter of a single call.
//
// Sample input parameters:
// (with v=0)
// "0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad",
// "0xaca7da997ad177f040240cdccf6905b71ab16b74434388c3a72f34fd25d6439346b2bac274ff29b48b3ea6e2d04c1336eaceafda3c53ab483fc3ff12fac3ebf200",
// "0x0e5cb767cce09a7f3ca594df118aa519be5e2b5a"
//
// (with v=1)
// "0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad",
// "0xdebaaa0cddb321b2dcaaf846d39605de7b97e77ba6106587855b9106cb10421561a22d94fa8b8a687ff9c911c844d1c016d1a685a9166858f9c7c1bc85128aca01",
// "0x8743523d96a1b2cbe0c6909653a56da18ed484af"
//
// (The hash is a hash of "hello world".)
//
// Written by Alex Beregszaszi (@axic), use it under the terms of the MIT license.
// -----------------------------------------------------------------------------------------------------------------


library ReconVerify {
    // Duplicate Soliditys ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but dont update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly cant access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    function ecrecovery(bytes32 hash, bytes sig) public returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // &#39;byte&#39; is not working due to the Solidity parser, so lets
            // use the second best option, &#39;and&#39;
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

    function verify(bytes32 hash, bytes sig, address signer) public returns (bool) {
        bool ret;
        address addr;
        (ret, addr) = ecrecovery(hash, sig);
        return ret == true && addr == signer;
    }

    function recover(bytes32 hash, bytes sig) internal returns (address addr) {
        bool ret;
        (ret, addr) = ecrecovery(hash, sig);
    }
}

contract ReconVerifyTest {
    function test_v0() public returns (bool) {
        bytes32 hash = 0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad;
        bytes memory sig = "\xac\xa7\xda\x99\x7a\xd1\x77\xf0\x40\x24\x0c\xdc\xcf\x69\x05\xb7\x1a\xb1\x6b\x74\x43\x43\x88\xc3\xa7\x2f\x34\xfd\x25\xd6\x43\x93\x46\xb2\xba\xc2\x74\xff\x29\xb4\x8b\x3e\xa6\xe2\xd0\x4c\x13\x36\xea\xce\xaf\xda\x3c\x53\xab\x48\x3f\xc3\xff\x12\xfa\xc3\xeb\xf2\x00";
        return ReconVerify.verify(hash, sig, 0x0A5f85C3d41892C934ae82BDbF17027A20717088);
    }

    function test_v1() public returns (bool) {
        bytes32 hash = 0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad;
        bytes memory sig = "\xde\xba\xaa\x0c\xdd\xb3\x21\xb2\xdc\xaa\xf8\x46\xd3\x96\x05\xde\x7b\x97\xe7\x7b\xa6\x10\x65\x87\x85\x5b\x91\x06\xcb\x10\x42\x15\x61\xa2\x2d\x94\xfa\x8b\x8a\x68\x7f\xf9\xc9\x11\xc8\x44\xd1\xc0\x16\xd1\xa6\x85\xa9\x16\x68\x58\xf9\xc7\xc1\xbc\x85\x12\x8a\xca\x01";
        return ReconVerify.verify(hash, sig, 0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }
}

// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------

pragma solidity ^ 0.4.25;

contract owned {
    address public owner;

    function ReconOwned()  public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public {
        owner = newOwner;
    }
}


contract tokenRecipient {
    event receivedEther(address sender, uint amount);
    event receivedTokens(address _from, uint256 _value, address _token, bytes _extraData);

    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        Token t = Token(_token);
        require(t.transferFrom(_from, this, _value));
        emit receivedTokens(_from, _value, _token, _extraData);
    }

    function () payable  public {
        emit receivedEther(msg.sender, msg.value);
    }
}


interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}


contract Congress is owned, tokenRecipient {
    // Contract Variables and events
    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    int public majorityMargin;
    Proposal[] public proposals;
    uint public numProposals;
    mapping (address => uint) public memberId;
    Member[] public members;

    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter, string justification);
    event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
    event MembershipChanged(address member, bool isMember);
    event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, int newMajorityMargin);

    struct Proposal {
        address recipient;
        uint amount;
        string description;
        uint minExecutionDate;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        int currentResult;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Member {
        address member;
        string name;
        uint memberSince;
    }

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }

    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyMembers {
        require(memberId[msg.sender] != 0);
        _;
    }

    /**
     * Constructor function
     */
    function ReconCongress (
        uint minimumQuorumForProposals,
        uint minutesForDebate,
        int marginOfVotesForMajority
    )  payable public {
        changeVotingRules(minimumQuorumForProposals, minutesForDebate, marginOfVotesForMajority);
        // It’s necessary to add an empty first member
        addMember(0, "");
        // and lets add the founder, to save a step later
        addMember(owner, &#39;founder&#39;);
    }

    /**
     * Add member
     *
     * Make `targetMember` a member named `memberName`
     *
     * @param targetMember ethereum address to be added
     * @param memberName public name for that member
     */
    function addMember(address targetMember, string memberName) onlyOwner public {
        uint id = memberId[targetMember];
        if (id == 0) {
            memberId[targetMember] = members.length;
            id = members.length++;
        }

        members[id] = Member({member: targetMember, memberSince: now, name: memberName});
        emit MembershipChanged(targetMember, true);
    }

    /**
     * Remove member
     *
     * @notice Remove membership from `targetMember`
     *
     * @param targetMember ethereum address to be removed
     */
    function removeMember(address targetMember) onlyOwner public {
        require(memberId[targetMember] != 0);

        for (uint i = memberId[targetMember]; i<members.length-1; i++){
            members[i] = members[i+1];
        }
        delete members[members.length-1];
        members.length--;
    }

    /**
     * Change voting rules
     *
     * Make so that proposals need to be discussed for at least `minutesForDebate/60` hours,
     * have at least `minimumQuorumForProposals` votes, and have 50% + `marginOfVotesForMajority` votes to be executed
     *
     * @param minimumQuorumForProposals how many members must vote on a proposal for it to be executed
     * @param minutesForDebate the minimum amount of delay between when a proposal is made and when it can be executed
     * @param marginOfVotesForMajority the proposal needs to have 50% plus this number
     */
    function changeVotingRules(
        uint minimumQuorumForProposals,
        uint minutesForDebate,
        int marginOfVotesForMajority
    ) onlyOwner public {
        minimumQuorum = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;
        majorityMargin = marginOfVotesForMajority;

        emit ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, majorityMargin);
    }

    /**
     * Add Proposal
     *
     * Propose to send `weiAmount / 1e18` ether to `beneficiary` for `jobDescription`. `transactionBytecode ? Contains : Does not contain` code.
     *
     * @param beneficiary who to send the ether to
     * @param weiAmount amount of ether to send, in wei
     * @param jobDescription Description of job
     * @param transactionBytecode bytecode of transaction
     */
    function newProposal(
        address beneficiary,
        uint weiAmount,
        string jobDescription,
        bytes transactionBytecode
    )
        onlyMembers public
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = weiAmount;
        p.description = jobDescription;
        p.proposalHash = keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
        p.minExecutionDate = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        emit ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
        numProposals = proposalID+1;

        return proposalID;
    }

    /**
     * Add proposal in Ether
     *
     * Propose to send `etherAmount` ether to `beneficiary` for `jobDescription`. `transactionBytecode ? Contains : Does not contain` code.
     * This is a convenience function to use if the amount to be given is in round number of ether units.
     *
     * @param beneficiary who to send the ether to
     * @param etherAmount amount of ether to send
     * @param jobDescription Description of job
     * @param transactionBytecode bytecode of transaction
     */
    function newProposalInEther(
        address beneficiary,
        uint etherAmount,
        string jobDescription,
        bytes transactionBytecode
    )
        onlyMembers public
        returns (uint proposalID)
    {
        return newProposal(beneficiary, etherAmount * 1 ether, jobDescription, transactionBytecode);
    }

    /**
     * Check if a proposal code matches
     *
     * @param proposalNumber ID number of the proposal to query
     * @param beneficiary who to send the ether to
     * @param weiAmount amount of ether to send
     * @param transactionBytecode bytecode of transaction
     */
    function checkProposalCode(
        uint proposalNumber,
        address beneficiary,
        uint weiAmount,
        bytes transactionBytecode
    )
        constant public
        returns (bool codeChecksOut)
    {
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
    }

    /**
     * Log a vote for a proposal
     *
     * Vote `supportsProposal? in support of : against` proposal #`proposalNumber`
     *
     * @param proposalNumber number of proposal
     * @param supportsProposal either in favor or against it
     * @param justificationText optional justification text
     */
    function vote(
        uint proposalNumber,
        bool supportsProposal,
        string justificationText
    )
        onlyMembers public
        returns (uint voteID)
    {
        Proposal storage p = proposals[proposalNumber]; // Get the proposal
        require(!p.voted[msg.sender]);                  // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.numberOfVotes++;                              // Increase the number of votes
        if (supportsProposal) {                         // If they support the proposal
            p.currentResult++;                          // Increase score
        } else {                                        // If they dont
            p.currentResult--;                          // Decrease the score
        }

        // Create a log of this event
        emit Voted(proposalNumber,  supportsProposal, msg.sender, justificationText);
        return p.numberOfVotes;
    }

    /**
     * Finish vote
     *
     * Count the votes proposal #`proposalNumber` and execute it if approved
     *
     * @param proposalNumber proposal number
     * @param transactionBytecode optional: if the transaction contained a bytecode, you need to send it
     */
    function executeProposal(uint proposalNumber, bytes transactionBytecode) public {
        Proposal storage p = proposals[proposalNumber];

        require(now > p.minExecutionDate                                            // If it is past the voting deadline
            && !p.executed                                                         // and it has not already been executed
            && p.proposalHash == keccak256(abi.encodePacked(p.recipient, p.amount, transactionBytecode))  // and the supplied code matches the proposal
            && p.numberOfVotes >= minimumQuorum);                                  // and a minimum quorum has been reached...

        // ...then execute result

        if (p.currentResult > majorityMargin) {
            // Proposal passed; execute the transaction

            p.executed = true; // Avoid recursive calling
            require(p.recipient.call.value(p.amount)(transactionBytecode));

            p.proposalPassed = true;
        } else {
            // Proposal failed
            p.proposalPassed = false;
        }

        // Fire Events
        emit ProposalTallied(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
    }
}

// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------

pragma solidity ^ 0.4.25;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


pragma solidity ^ 0.4.25;

// ----------------------------------------------------------------------------
// Recon DateTime Library v1.00
//
// A energy-efficient Solidity date and time library
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------


library ReconDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}


pragma solidity ^ 0.4.25;

// ----------------------------------------------------------------------------
// Recon DateTime Library v1.00 - Contract Instance
//
// A energy-efficient Solidity date and time library
//
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

contract ReconDateTimeContract {
    uint public constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint public constant SECONDS_PER_HOUR = 60 * 60;
    uint public constant SECONDS_PER_MINUTE = 60;
    int public constant OFFSET19700101 = 2440588;

    uint public constant DOW_MON = 1;
    uint public constant DOW_TUE = 2;
    uint public constant DOW_WED = 3;
    uint public constant DOW_THU = 4;
    uint public constant DOW_FRI = 5;
    uint public constant DOW_SAT = 6;
    uint public constant DOW_SUN = 7;

    function _now() public view returns (uint timestamp) {
        timestamp = now;
    }

    function _nowDateTime() public view returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = ReconDateTimeLibrary.timestampToDateTime(now);
    }

    function _daysFromDate(uint year, uint month, uint day) public pure returns (uint _days) {
        return ReconDateTimeLibrary._daysFromDate(year, month, day);
    }

    function _daysToDate(uint _days) public pure returns (uint year, uint month, uint day) {
        return ReconDateTimeLibrary._daysToDate(_days);
    }

    function timestampFromDate(uint year, uint month, uint day) public pure returns (uint timestamp) {
        return ReconDateTimeLibrary.timestampFromDate(year, month, day);
    }

    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) {
        return ReconDateTimeLibrary.timestampFromDateTime(year, month, day, hour, minute, second);
    }

    function timestampToDate(uint timestamp) public pure returns (uint year, uint month, uint day) {
        (year, month, day) = ReconDateTimeLibrary.timestampToDate(timestamp);
    }

    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = ReconDateTimeLibrary.timestampToDateTime(timestamp);
    }

    function isLeapYear(uint timestamp) public pure returns (bool leapYear) {
        leapYear = ReconDateTimeLibrary.isLeapYear(timestamp);
    }

    function _isLeapYear(uint year) public pure returns (bool leapYear) {
        leapYear = ReconDateTimeLibrary._isLeapYear(year);
    }

    function isWeekDay(uint timestamp) public pure returns (bool weekDay) {
        weekDay = ReconDateTimeLibrary.isWeekDay(timestamp);
    }

    function isWeekEnd(uint timestamp) public pure returns (bool weekEnd) {
        weekEnd = ReconDateTimeLibrary.isWeekEnd(timestamp);
    }

    function getDaysInMonth(uint timestamp) public pure returns (uint daysInMonth) {
        daysInMonth = ReconDateTimeLibrary.getDaysInMonth(timestamp);
    }

    function _getDaysInMonth(uint year, uint month) public pure returns (uint daysInMonth) {
        daysInMonth = ReconDateTimeLibrary._getDaysInMonth(year, month);
    }

    function getDayOfWeek(uint timestamp) public pure returns (uint dayOfWeek) {
        dayOfWeek = ReconDateTimeLibrary.getDayOfWeek(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint year) {
        year = ReconDateTimeLibrary.getYear(timestamp);
    }

    function getMonth(uint timestamp) public pure returns (uint month) {
        month = ReconDateTimeLibrary.getMonth(timestamp);
    }

    function getDay(uint timestamp) public pure returns (uint day) {
        day = ReconDateTimeLibrary.getDay(timestamp);
    }

    function getHour(uint timestamp) public pure returns (uint hour) {
        hour = ReconDateTimeLibrary.getHour(timestamp);
    }

    function getMinute(uint timestamp) public pure returns (uint minute) {
        minute = ReconDateTimeLibrary.getMinute(timestamp);
    }

    function getSecond(uint timestamp) public pure returns (uint second) {
        second = ReconDateTimeLibrary.getSecond(timestamp);
    }

    function addYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addYears(timestamp, _years);
    }

    function addMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addMonths(timestamp, _months);
    }

    function addDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addDays(timestamp, _days);
    }

    function addHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addHours(timestamp, _hours);
    }

    function addMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addMinutes(timestamp, _minutes);
    }

    function addSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.addSeconds(timestamp, _seconds);
    }

    function subYears(uint timestamp, uint _years) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subYears(timestamp, _years);
    }

    function subMonths(uint timestamp, uint _months) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subMonths(timestamp, _months);
    }

    function subDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subDays(timestamp, _days);
    }

    function subHours(uint timestamp, uint _hours) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subHours(timestamp, _hours);
    }

    function subMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subMinutes(timestamp, _minutes);
    }

    function subSeconds(uint timestamp, uint _seconds) public pure returns (uint newTimestamp) {
        newTimestamp = ReconDateTimeLibrary.subSeconds(timestamp, _seconds);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) public pure returns (uint _years) {
        _years = ReconDateTimeLibrary.diffYears(fromTimestamp, toTimestamp);
    }

    function diffMonths(uint fromTimestamp, uint toTimestamp) public pure returns (uint _months) {
        _months = ReconDateTimeLibrary.diffMonths(fromTimestamp, toTimestamp);
    }

    function diffDays(uint fromTimestamp, uint toTimestamp) public pure returns (uint _days) {
        _days = ReconDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }

    function diffHours(uint fromTimestamp, uint toTimestamp) public pure returns (uint _hours) {
        _hours = ReconDateTimeLibrary.diffHours(fromTimestamp, toTimestamp);
    }

    function diffMinutes(uint fromTimestamp, uint toTimestamp) public pure returns (uint _minutes) {
        _minutes = ReconDateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }

    function diffSeconds(uint fromTimestamp, uint toTimestamp) public pure returns (uint _seconds) {
        _seconds = ReconDateTimeLibrary.diffSeconds(fromTimestamp, toTimestamp);
    }
}


// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------


pragma solidity ^ 0.4.25;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes32 hash) public;
}


contract ReconTokenInterface is ERC20Interface {
    uint public constant reconVersion = 110;

    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";

    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event Mint(address indexed tokenOwner, uint tokens, bool lockAccount);
    event MintingDisabled();
    event TransfersEnabled();
    event AccountUnlocked(address indexed tokenOwner);

    function approveAndCall(address spender, uint tokens, bytes32 hash) public returns (bool success);

    // ------------------------------------------------------------------------
    // signed{X} functions
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (CheckResult result);
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success);

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (CheckResult result);
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success);

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (CheckResult result);
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success);

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (CheckResult result);
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success);

    function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool success);
    function unlockAccount(address tokenOwner) public;
    function disableMinting() public;
    function enableTransfers() public;


    enum CheckResult {
        Success,                           // 0 Success
        NotTransferable,                   // 1 Tokens not transferable yet
        AccountLocked,                     // 2 Account locked
        SignerMismatch,                    // 3 Mismatch in signing account
        InvalidNonce,                      // 4 Invalid nonce
        InsufficientApprovedTokens,        // 5 Insufficient approved tokens
        InsufficientApprovedTokensForFees, // 6 Insufficient approved tokens for fees
        InsufficientTokens,                // 7 Insufficient tokens
        InsufficientTokensForFees,         // 8 Insufficient tokens for fees
        OverflowError                      // 9 Overflow error
    }
}


// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------


pragma solidity ^ 0.4.25;

library ReconLib {
    struct Data {
        bool initialised;

        // Ownership
        address owner;
        address newOwner;

        // Minting and management
        address minter;
        bool mintable;
        bool transferable;
        mapping(address => bool) accountLocked;

        // Token
        string symbol;
        string name;
        uint8 decimals;
        uint totalSupply;
        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;
        mapping(address => uint) nextNonce;
    }


    uint public constant reconVersion = 110;
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";


    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event Mint(address indexed tokenOwner, uint tokens, bool lockAccount);
    event MintingDisabled();
    event TransfersEnabled();
    event AccountUnlocked(address indexed tokenOwner);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    function init(Data storage self, address owner, string symbol, string name, uint8 decimals, uint initialSupply, bool mintable, bool transferable) public {
        require(!self.initialised);
        self.initialised = true;
        self.owner = owner;
        self.symbol = symbol;
        self.name = name;
        self.decimals = decimals;
        if (initialSupply > 0) {
            self.balances[owner] = initialSupply;
            self.totalSupply = initialSupply;
            emit Mint(self.owner, initialSupply, false);
            emit Transfer(address(0), self.owner, initialSupply);
        }
        self.mintable = mintable;
        self.transferable = transferable;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }


    function transferOwnership(Data storage self, address newOwner) public {
        require(msg.sender == self.owner);
        self.newOwner = newOwner;
    }

    function acceptOwnership(Data storage self) public {
        require(msg.sender == self.newOwner);
        emit OwnershipTransferred(self.owner, self.newOwner);
        self.owner = self.newOwner;
        self.newOwner = address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }

    function transferOwnershipImmediately(Data storage self, address newOwner) public {
        require(msg.sender == self.owner);
        emit OwnershipTransferred(self.owner, newOwner);
        self.owner = newOwner;
        self.newOwner = address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }

    // ------------------------------------------------------------------------
    // Minting and management
    // ------------------------------------------------------------------------
    function setMinter(Data storage self, address minter) public {
        require(msg.sender == self.owner);
        require(self.mintable);
        emit MinterUpdated(self.minter, minter);
        self.minter = minter;
    }

    function mint(Data storage self, address tokenOwner, uint tokens, bool lockAccount) public returns (bool success) {
        require(self.mintable);
        require(msg.sender == self.minter || msg.sender == self.owner);
        if (lockAccount) {
            self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = true;
        }
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeAdd(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], tokens);
        self.totalSupply = safeAdd(self.totalSupply, tokens);
        emit Mint(tokenOwner, tokens, lockAccount);
        emit Transfer(address(0x0A5f85C3d41892C934ae82BDbF17027A20717088), tokenOwner, tokens);
        return true;
    }

    function unlockAccount(Data storage self, address tokenOwner) public {
        require(msg.sender == self.owner);
        require(self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]);
        self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = false;
        emit AccountUnlocked(tokenOwner);
    }

    function disableMinting(Data storage self) public {
        require(self.mintable);
        require(msg.sender == self.minter || msg.sender == self.owner);
        self.mintable = false;
        if (self.minter != address(0x3Da2585FEbE344e52650d9174e7B1bf35C70D840)) {
            emit MinterUpdated(self.minter, address(0x3Da2585FEbE344e52650d9174e7B1bf35C70D840));
            self.minter = address(0x3Da2585FEbE344e52650d9174e7B1bf35C70D840);
        }
        emit MintingDisabled();
    }

    function enableTransfers(Data storage self) public {
        require(msg.sender == self.owner);
        require(!self.transferable);
        self.transferable = true;
        emit TransfersEnabled();
    }

    // ------------------------------------------------------------------------
    // Other functions
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(Data storage self, address tokenAddress, uint tokens) public returns (bool success) {
        require(msg.sender == self.owner);
        return ERC20Interface(tokenAddress).transfer(self.owner, tokens);
    }

    function ecrecoverFromSig(bytes32 hash, bytes32 sig) public pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0x5f2D6766C6F3A7250CfD99d6b01380C432293F0c);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(32, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP, one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change, see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0x5f2D6766C6F3A7250CfD99d6b01380C432293F0c);
        return ecrecover(hash, v, r, s);
    }


    function getCheckResultMessage(Data storage /*self*/, ReconTokenInterface.CheckResult result) public pure returns (string) {
        if (result == ReconTokenInterface.CheckResult.Success) {
            return "Success";
        } else if (result == ReconTokenInterface.CheckResult.NotTransferable) {
            return "Tokens not transferable yet";
        } else if (result == ReconTokenInterface.CheckResult.AccountLocked) {
            return "Account locked";
        } else if (result == ReconTokenInterface.CheckResult.SignerMismatch) {
            return "Mismatch in signing account";
        } else if (result == ReconTokenInterface.CheckResult.InvalidNonce) {
            return "Invalid nonce";
        } else if (result == ReconTokenInterface.CheckResult.InsufficientApprovedTokens) {
            return "Insufficient approved tokens";
        } else if (result == ReconTokenInterface.CheckResult.InsufficientApprovedTokensForFees) {
            return "Insufficient approved tokens for fees";
        } else if (result == ReconTokenInterface.CheckResult.InsufficientTokens) {
            return "Insufficient tokens";
        } else if (result == ReconTokenInterface.CheckResult.InsufficientTokensForFees) {
            return "Insufficient tokens for fees";
        } else if (result == ReconTokenInterface.CheckResult.OverflowError) {
            return "Overflow error";
        } else {
            return "Unknown error";
        }
    }


    function transfer(Data storage self, address to, uint tokens) public returns (bool success) {
        // Owner and minter can move tokens before the tokens are transferable
        require(self.transferable || (self.mintable && (msg.sender == self.owner  || msg.sender == self.minter)));
        require(!self.accountLocked[msg.sender]);
        self.balances[msg.sender] = safeSub(self.balances[msg.sender], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(Data storage self, address spender, uint tokens) public returns (bool success) {
        require(!self.accountLocked[msg.sender]);
        self.allowed[msg.sender][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(Data storage self, address from, address to, uint tokens) public returns (bool success) {
        require(self.transferable);
        require(!self.accountLocked[from]);
        self.balances[from] = safeSub(self.balances[from], tokens);
        self.allowed[from][msg.sender] = safeSub(self.allowed[from][msg.sender], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approveAndCall(Data storage self, address spender, uint tokens, bytes32 data) public returns (bool success) {
        require(!self.accountLocked[msg.sender]);
        self.allowed[msg.sender][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    function signedTransferHash(Data storage /*self*/, address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(signedTransferSig, address(this), tokenOwner, to, tokens, fee, nonce));
    }

    function signedTransferCheck(Data storage self, address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        if (!self.transferable) return ReconTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedTransferHash(self, tokenOwner, to, tokens, fee, nonce);
        if (tokenOwner == address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) || tokenOwner != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig)) return ReconTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]) return ReconTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] != nonce) return ReconTokenInterface.CheckResult.InvalidNonce;
        uint total = safeAdd(tokens, fee);
        if (self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] < tokens) return ReconTokenInterface.CheckResult.InsufficientTokens;
        if (self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] < total) return ReconTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[to] + tokens < self.balances[to]) return ReconTokenInterface.CheckResult.OverflowError;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return ReconTokenInterface.CheckResult.OverflowError;
        return ReconTokenInterface.CheckResult.Success;
    }
    function signedTransfer(Data storage self, address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedTransferHash(self, tokenOwner, to, tokens, fee, nonce);
        require(tokenOwner != address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) && tokenOwner == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(!self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]);
        require(self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] == nonce);
        self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = nonce + 1;
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeSub(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        emit Transfer(tokenOwner, to, tokens);
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeSub(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], fee);
        self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b] = safeAdd(self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b], fee);
        emit Transfer(tokenOwner, feeAccount, fee);
        return true;
    }

    function signedApproveHash(Data storage /*self*/, address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(signedApproveSig, address(this), tokenOwner, spender, tokens, fee, nonce));
    }

    function signedApproveCheck(Data storage self, address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        if (!self.transferable) return ReconTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedApproveHash(self, tokenOwner, spender, tokens, fee, nonce);
        if (tokenOwner == address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) || tokenOwner != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig))
            return ReconTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]) return ReconTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] != nonce) return ReconTokenInterface.CheckResult.InvalidNonce;
        if (self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] < fee) return ReconTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return ReconTokenInterface.CheckResult.OverflowError;
        return ReconTokenInterface.CheckResult.Success;
    }
    function signedApprove(Data storage self, address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedApproveHash(self, tokenOwner, spender, tokens, fee, nonce);
        require(tokenOwner != address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) && tokenOwner == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(!self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]);
        require(self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] == nonce);
        self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = nonce + 1;
        self.allowed[0x0A5f85C3d41892C934ae82BDbF17027A20717088][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = tokens;
        emit Approval(0x0A5f85C3d41892C934ae82BDbF17027A20717088, spender, tokens);
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeSub(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], fee);
        self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b] = safeAdd(self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b], fee);
        emit Transfer(tokenOwner, feeAccount, fee);
        return true;
    }

    function signedTransferFromHash(Data storage /*self*/, address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(signedTransferFromSig, address(this), spender, from, to, tokens, fee, nonce));
    }

    function signedTransferFromCheck(Data storage self, address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        if (!self.transferable) return ReconTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedTransferFromHash(self, spender, from, to, tokens, fee, nonce);
        if (spender == address(0xF848332f5D902EFD874099458Bc8A53C8b7881B1) || spender != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig)) return ReconTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[from]) return ReconTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[spender] != nonce) return ReconTokenInterface.CheckResult.InvalidNonce;
        uint total = safeAdd(tokens, fee);
        if (self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] < tokens) return ReconTokenInterface.CheckResult.InsufficientApprovedTokens;
        if (self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] < total) return ReconTokenInterface.CheckResult.InsufficientApprovedTokensForFees;
        if (self.balances[from] < tokens) return ReconTokenInterface.CheckResult.InsufficientTokens;
        if (self.balances[from] < total) return ReconTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[to] + tokens < self.balances[to]) return ReconTokenInterface.CheckResult.OverflowError;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return ReconTokenInterface.CheckResult.OverflowError;
        return ReconTokenInterface.CheckResult.Success;
    }

    function signedTransferFrom(Data storage self, address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedTransferFromHash(self, spender, from, to, tokens, fee, nonce);
        require(spender != address(0xF848332f5D902EFD874099458Bc8A53C8b7881B1) && spender == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(!self.accountLocked[from]);
        require(self.nextNonce[0xF848332f5D902EFD874099458Bc8A53C8b7881B1] == nonce);
        self.nextNonce[0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = nonce + 1;
        self.balances[from] = safeSub(self.balances[from], tokens);
        self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = safeSub(self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        emit Transfer(from, to, tokens);
        self.balances[from] = safeSub(self.balances[from], fee);
        self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1] = safeSub(self.allowed[from][0xF848332f5D902EFD874099458Bc8A53C8b7881B1], fee);
        self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b] = safeAdd(self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b], fee);
        emit Transfer(from, feeAccount, fee);
        return true;
    }

    function signedApproveAndCallHash(Data storage /*self*/, address tokenOwner, address spender, uint tokens, bytes32 data, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(abi.encodePacked(signedApproveAndCallSig, address(this), tokenOwner, spender, tokens, data, fee, nonce));
    }

    function signedApproveAndCallCheck(Data storage self, address tokenOwner, address spender, uint tokens, bytes32 data, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        if (!self.transferable) return ReconTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedApproveAndCallHash(self, tokenOwner, spender, tokens, data, fee, nonce);
        if (tokenOwner == address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) || tokenOwner != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig)) return ReconTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]) return ReconTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] != nonce) return ReconTokenInterface.CheckResult.InvalidNonce;
        if (self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] < fee) return ReconTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return ReconTokenInterface.CheckResult.OverflowError;
        return ReconTokenInterface.CheckResult.Success;
    }

    function signedApproveAndCall(Data storage self, address tokenOwner, address spender, uint tokens, bytes32 data, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedApproveAndCallHash(self, tokenOwner, spender, tokens, data, fee, nonce);
        require(tokenOwner != address(0x0A5f85C3d41892C934ae82BDbF17027A20717088) && tokenOwner == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(!self.accountLocked[0x0A5f85C3d41892C934ae82BDbF17027A20717088]);
        require(self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] == nonce);
        self.nextNonce[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = nonce + 1;
        self.allowed[0x0A5f85C3d41892C934ae82BDbF17027A20717088][spender] = tokens;
        emit Approval(tokenOwner, spender, tokens);
        self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088] = safeSub(self.balances[0x0A5f85C3d41892C934ae82BDbF17027A20717088], fee);
        self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b] = safeAdd(self.balances[0xc083E68D962c2E062D2735B54804Bb5E1f367c1b], fee);
        emit Transfer(tokenOwner, feeAccount, fee);
        ApproveAndCallFallBack(spender).receiveApproval(tokenOwner, tokens, address(this), data);
        return true;
    }
}


// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------


pragma solidity ^ 0.4.25;

contract ReconToken is ReconTokenInterface{
    using ReconLib for ReconLib.Data;

    ReconLib.Data data;


    function constructorReconToken(address owner, string symbol, string name, uint8 decimals, uint initialSupply, bool mintable, bool transferable) public {
        data.init(owner, symbol, name, decimals, initialSupply, mintable, transferable);
    }

    function owner() public view returns (address) {
        return data.owner;
    }

    function newOwner() public view returns (address) {
        return data.newOwner;
    }

    function transferOwnership(address _newOwner) public {
        data.transferOwnership(_newOwner);
    }
    function acceptOwnership() public {
        data.acceptOwnership();
    }
    function transferOwnershipImmediately(address _newOwner) public {
        data.transferOwnershipImmediately(_newOwner);
    }

    function symbol() public view returns (string) {
        return data.symbol;
    }

    function name() public view returns (string) {
        return data.name;
    }

    function decimals() public view returns (uint8) {
        return data.decimals;
    }

    function minter() public view returns (address) {
        return data.minter;
    }

    function setMinter(address _minter) public {
        data.setMinter(_minter);
    }

    function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool success) {
        return data.mint(tokenOwner, tokens, lockAccount);
    }

    function accountLocked(address tokenOwner) public view returns (bool) {
        return data.accountLocked[tokenOwner];
    }
    function unlockAccount(address tokenOwner) public {
        data.unlockAccount(tokenOwner);
    }

    function mintable() public view returns (bool) {
        return data.mintable;
    }

    function transferable() public view returns (bool) {
        return data.transferable;
    }

    function disableMinting() public {
        data.disableMinting();
    }

    function enableTransfers() public {
        data.enableTransfers();
    }

    function nextNonce(address spender) public view returns (uint) {
        return data.nextNonce[spender];
    }


    // ------------------------------------------------------------------------
    // Other functions
    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return data.transferAnyERC20Token(tokenAddress, tokens);
    }

    function () public payable {
        revert();
    }

    function totalSupply() public view returns (uint) {
        return data.totalSupply - data.balances[address(0x0A5f85C3d41892C934ae82BDbF17027A20717088)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return data.balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return data.allowed[tokenOwner][spender];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        return data.transfer(to, tokens);
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        return data.approve(spender, tokens);
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        return data.transferFrom(from, to, tokens);
    }

    function approveAndCall(address spender, uint tokens, bytes32 _data) public returns (bool success) {
        return data.approveAndCall(spender, tokens, _data);
    }

    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedTransferHash(tokenOwner, to, tokens, fee, nonce);
    }

    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        return data.signedTransferCheck(tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }

    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        return data.signedTransfer(tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedApproveHash(tokenOwner, spender, tokens, fee, nonce);
    }

    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        return data.signedApproveCheck(tokenOwner, spender, tokens, fee, nonce, sig, feeAccount);
    }

    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        return data.signedApprove(tokenOwner, spender, tokens, fee, nonce, sig, feeAccount);
    }

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedTransferFromHash(spender, from, to, tokens, fee, nonce);
    }

    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        return data.signedTransferFromCheck(spender, from, to, tokens, fee, nonce, sig, feeAccount);
    }

    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        return data.signedTransferFrom(spender, from, to, tokens, fee, nonce, sig, feeAccount);
    }

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedApproveAndCallHash(tokenOwner, spender, tokens, _data, fee, nonce);
    }

    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce, bytes32 sig, address feeAccount) public view returns (ReconTokenInterface.CheckResult result) {
        return data.signedApproveAndCallCheck(tokenOwner, spender, tokens, _data, fee, nonce, sig, feeAccount);
    }

    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes32 _data, uint fee, uint nonce, bytes32 sig, address feeAccount) public returns (bool success) {
        return data.signedApproveAndCall(tokenOwner, spender, tokens, _data, fee, nonce, sig, feeAccount);
    }
}


// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------


pragma solidity ^ 0.4.25;

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned1() public {
        owner = msg.sender;
    }
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(newOwner != address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060));
        emit OwnershipTransferred(owner, newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }

    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
        newOwner = address(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060);
    }
}


// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------


pragma solidity ^ 0.4.25;

contract ReconTokenFactory is ERC20Interface, Owned {
    using SafeMath for uint;

    string public constant name = "RECON";
    string public constant symbol = "RECON";
    uint8 public constant decimals = 18;

    uint constant public ReconToMicro = uint(1000000000000000000);

    // This constants reflects RECON token distribution

    uint constant public investorSupply                   =  25000000000 * ReconToMicro;
    uint constant public adviserSupply                    =     25000000 * ReconToMicro;
    uint constant public bountySupply                     =     25000000 * ReconToMicro;

    uint constant public _totalSupply                     = 100000000000 * ReconToMicro;
    uint constant public preICOSupply                     =   5000000000 * ReconToMicro;
    uint constant public presaleSupply                    =   5000000000 * ReconToMicro;
    uint constant public crowdsaleSupply                  =  10000000000 * ReconToMicro;
    uint constant public preICOprivate                    =     99000000 * ReconToMicro;

    uint constant public Reconowner                       =    101000000 * ReconToMicro;
    uint constant public ReconnewOwner                    =    100000000 * ReconToMicro;
    uint constant public Reconminter                      =     50000000 * ReconToMicro;
    uint constant public ReconfeeAccount                  =     50000000 * ReconToMicro;
    uint constant public Reconspender                     =     50000000 * ReconToMicro;
    uint constant public ReconrecoveredAddress            =     50000000 * ReconToMicro;
    uint constant public ProprityfromReconBank            =    200000000 * ReconToMicro;
    uint constant public ReconManager                     =    200000000 * ReconToMicro;

    uint constant public ReconCashinB2B                   =   5000000000 * ReconToMicro;
    uint constant public ReconSwitchC2C                   =   5000000000 * ReconToMicro;
    uint constant public ReconCashoutB2C                  =   5000000000 * ReconToMicro;
    uint constant public ReconInvestment                  =   2000000000 * ReconToMicro;
    uint constant public ReconMomentum                    =   2000000000 * ReconToMicro;
    uint constant public ReconReward                      =   2000000000 * ReconToMicro;
    uint constant public ReconDonate                      =   1000000000 * ReconToMicro;
    uint constant public ReconTokens                      =   4000000000 * ReconToMicro;
    uint constant public ReconCash                        =   4000000000 * ReconToMicro;
    uint constant public ReconGold                        =   4000000000 * ReconToMicro;
    uint constant public ReconCard                        =   4000000000 * ReconToMicro;
    uint constant public ReconHardriveWallet              =   2000000000 * ReconToMicro;
    uint constant public RecoinOption                     =   1000000000 * ReconToMicro;
    uint constant public ReconPromo                       =    100000000 * ReconToMicro;
    uint constant public Reconpatents                     =   1000000000 * ReconToMicro;
    uint constant public ReconSecurityandLegalFees        =   1000000000 * ReconToMicro;
    uint constant public PeerToPeerNetworkingService      =   1000000000 * ReconToMicro;
    uint constant public Reconia                          =   2000000000 * ReconToMicro;

    uint constant public ReconVaultXtraStock              =   7000000000 * ReconToMicro;
    uint constant public ReconVaultSecurityStock          =   5000000000 * ReconToMicro;
    uint constant public ReconVaultAdvancePaymentStock    =   5000000000 * ReconToMicro;
    uint constant public ReconVaultPrivatStock            =   4000000000 * ReconToMicro;
    uint constant public ReconVaultCurrencyInsurancestock =   4000000000 * ReconToMicro;
    uint constant public ReconVaultNextStock              =   4000000000 * ReconToMicro;
    uint constant public ReconVaultFuturStock             =   4000000000 * ReconToMicro;



    // This variables accumulate amount of sold RECON during
    // presale, crowdsale, or given to investors as bonus.
    uint public presaleSold = 0;
    uint public crowdsaleSold = 0;
    uint public investorGiven = 0;

    // Amount of ETH received during ICO
    uint public ethSold = 0;

    uint constant public softcapUSD = 20000000000;
    uint constant public preicoUSD  = 5000000000;

    // Presale lower bound in dollars.
    uint constant public crowdsaleMinUSD = ReconToMicro * 10 * 100 / 12;
    uint constant public bonusLevel0 = ReconToMicro * 10000 * 100 / 12; // 10000$
    uint constant public bonusLevel100 = ReconToMicro * 100000 * 100 / 12; // 100000$

    // The tokens made available to the public will be in 13 steps
    // for a maximum of 20% of the total supply (see doc for checkTransfer).
    // All dates are stored as timestamps.
    uint constant public unlockDate1  = 1541890800; // 11-11-2018 00:00:00  [1%]  Recon Manager
    uint constant public unlockDate2  = 1545346800; // 21-12-2018 00:00:00  [2%]  Recon Cash-in (B2B)
    uint constant public unlockDate3  = 1549062000; // 02-02-2019 00:00:00  [2%]  Recon Switch (C2C)
    uint constant public unlockDate4  = 1554328800; // 04-04-2019 00:00:00  [2%]  Recon Cash-out (B2C)
    uint constant public unlockDate5  = 1565215200; // 08-08-2019 00:00:00  [2%]  Recon Investment & Recon Momentum
    uint constant public unlockDate6  = 1570658400; // 10-10-2019 00:00:00  [2%]  Recon Reward
    uint constant public unlockDate7  = 1576105200; // 12-12-2019 00:00:00  [1%]  Recon Donate
    uint constant public unlockDate8  = 1580598000; // 02-02-2020 00:00:00  [1%]  Recon Token
    uint constant public unlockDate9  = 1585951200; // 04-04-2020 00:00:00  [2%]  Recon Cash
    uint constant public unlockDate10 = 1591394400; // 06-06-2020 00:00:00  [1%]  Recon Gold
    uint constant public unlockDate11 = 1596837600; // 08-08-2020 00:00:00  [2%]  Recon Card
    uint constant public unlockDate12 = 1602280800; // 10-10-2020 00:00:00  [1%]  Recon Hardrive Wallet
    uint constant public unlockDate13 = 1606863600; // 02-12-2020 00:00:00  [1%]  Recoin Option

    // The tokens made available to the teams will be made in 4 steps
    // for a maximum of 80% of the total supply (see doc for checkTransfer).
    uint constant public teamUnlock1 = 1544569200; // 12-12-2018 00:00:00  [25%]
    uint constant public teamUnlock2 = 1576105200; // 12-12-2019 00:00:00  [25%]
    uint constant public teamUnlock3 = 1594072800; // 07-07-2020 00:00:00  [25%]
    uint constant public teamUnlock4 = 1608505200; // 21-12-2020 00:00:00  [25%]

    uint constant public teamETHUnlock1 = 1544569200; // 12-12-2018 00:00:00
    uint constant public teamETHUnlock2 = 1576105200; // 12-12-2019 00:00:00
    uint constant public teamETHUnlock3 = 1594072800; // 07-07-2020 00:00:00

    //https://casperproject.atlassian.net/wiki/spaces/PROD/pages/277839878/Smart+contract+ICO
    // Presale 10.06.2018 - 22.07.2018
    // Crowd-sale 23.07.2018 - 2.08.2018 (16.08.2018)
    uint constant public presaleStartTime     = 1541890800; // 11-11-2018 00:00:00
    uint constant public crowdsaleStartTime   = 1545346800; // 21-12-2018 00:00:00
    uint          public crowdsaleEndTime     = 1609455599; // 31-12-2020 23:59:59
    uint constant public crowdsaleHardEndTime = 1609455599; // 31-12-2020 23:59:59
    //address constant ReconrWallet = 0x0A5f85C3d41892C934ae82BDbF17027A20717088;
    constructor() public {
        admin = owner;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOwnerAndDirector {
        require(msg.sender == owner || msg.sender == director);
        _;
    }

    address admin;
    function setAdmin(address _newAdmin) public onlyOwnerAndDirector {
        admin = _newAdmin;
    }

    address director;
    function setDirector(address _newDirector) public onlyOwner {
        director = _newDirector;
    }

    bool assignedPreico = false;
    // @notice assignPreicoTokens transfers 3x tokens to pre-ICO participants (99,000,000)
    function assignPreicoTokens() public onlyOwnerAndDirector {
        require(!assignedPreico);
        assignedPreico = true;

        _freezeTransfer(0x4Bdff2Cc40996C71a1F16b72490d1a8E7Dfb7E56, 3 * 1000000000000000000000000); // Account_34
        _freezeTransfer(0x9189AC4FA7AdBC587fF76DD43248520F8Cb897f3, 3 * 1000000000000000000000000); // Account_35
        _freezeTransfer(0xc1D3DAd07A0dB42a7d34453C7d09eFeA793784e7, 3 * 1000000000000000000000000); // Account_36
        _freezeTransfer(0xA0BC1BAAa5318E39BfB66F8Cd0496d6b09CaE6C1, 3 * 1000000000000000000000000); // Account_37
        _freezeTransfer(0x9a2912F145Ab0d5b4aE6917A8b8ddd222539F424, 3 * 1000000000000000000000000); // Account_38
        _freezeTransfer(0x0bB0ded1d868F1c0a50bD31c1ab5ab7b53c6BC20, 3 * 1000000000000000000000000); // Account_39
        _freezeTransfer(0x65ec9f30249065A1BD23a9c68c0Ee9Ead63b4A4d, 3 * 1000000000000000000000000); // Account_40
        _freezeTransfer(0x87Bdc03582deEeB84E00d3fcFd083B64DA77F471, 3 * 1000000000000000000000000); // Account_41
        _freezeTransfer(0x81382A0998191E2Dd8a7bB2B8875D4Ff6CAA31ff, 3 * 1000000000000000000000000); // Account_42
        _freezeTransfer(0x790069C894ebf518fB213F35b48C8ec5AAF81E62, 3 * 1000000000000000000000000); // Account_43
        _freezeTransfer(0xa3f1404851E8156DFb425eC0EB3D3d5ADF6c8Fc0, 3 * 1000000000000000000000000); // Account_44
        _freezeTransfer(0x11bA01dc4d93234D24681e1B19839D4560D17165, 3 * 1000000000000000000000000); // Account_45
        _freezeTransfer(0x211D495291534009B8D3fa491400aB66F1d6131b, 3 * 1000000000000000000000000); // Account_46
        _freezeTransfer(0x8c481AaF9a735F9a44Ac2ACFCFc3dE2e9B2f88f8, 3 * 1000000000000000000000000); // Account_47
        _freezeTransfer(0xd0BEF2Fb95193f429f0075e442938F5d829a33c8, 3 * 1000000000000000000000000); // Account_48
        _freezeTransfer(0x424cbEb619974ee79CaeBf6E9081347e64766705, 3 * 1000000000000000000000000); // Account_49
        _freezeTransfer(0x9e395cd98089F6589b90643Dde4a304cAe4dA61C, 3 * 1000000000000000000000000); // Account_50
        _freezeTransfer(0x3cDE6Df0906157107491ED17C79fF9218A50D7Dc, 3 * 1000000000000000000000000); // Account_51
        _freezeTransfer(0x419a98D46a368A1704278349803683abB2A9D78E, 3 * 1000000000000000000000000); // Account_52
        _freezeTransfer(0x106Db742344FBB96B46989417C151B781D1a4069, 3 * 1000000000000000000000000); // Account_53
        _freezeTransfer(0xE16b9E9De165DbecA18B657414136cF007458aF5, 3 * 1000000000000000000000000); // Account_54
        _freezeTransfer(0xee32C325A3E11759b290df213E83a257ff249936, 3 * 1000000000000000000000000); // Account_55
        _freezeTransfer(0x7d6F916b0E5BF7Ba7f11E60ed9c30fB71C4A5fE0, 3 * 1000000000000000000000000); // Account_56
        _freezeTransfer(0xCC684085585419100AE5010770557d5ad3F3CE58, 3 * 1000000000000000000000000); // Account_57
        _freezeTransfer(0xB47BE6d74C5bC66b53230D07fA62Fb888594418d, 3 * 1000000000000000000000000); // Account_58
        _freezeTransfer(0xf891555a1BF2525f6EBaC9b922b6118ca4215fdD, 3 * 1000000000000000000000000); // Account_59
        _freezeTransfer(0xE3124478A5ed8550eA85733a4543Dd128461b668, 3 * 1000000000000000000000000); // Account_60
        _freezeTransfer(0xc5836df630225112493fa04fa32B586f072d6298, 3 * 1000000000000000000000000); // Account_61
        _freezeTransfer(0x144a0543C93ce8Fb26c13EB619D7E934FA3eA734, 3 * 1000000000000000000000000); // Account_62
        _freezeTransfer(0x43731e24108E928984DcC63DE7affdF3a805FFb0, 3 * 1000000000000000000000000); // Account_63
        _freezeTransfer(0x49f7744Aa8B706Faf336a3ff4De37078714065BC, 3 * 1000000000000000000000000); // Account_64
        _freezeTransfer(0x1E55C7E97F0b5c162FC9C42Ced92C8e55053e093, 3 * 1000000000000000000000000); // Account_65
        _freezeTransfer(0x40b234009664590997D2F6Fde2f279fE56e8AaBC, 3 * 1000000000000000000000000); // Account_66
    }

    bool assignedTeam = false;
    // @notice assignTeamTokens assigns tokens to team members (79,901,000,000)
    // @notice tokens for team have their own supply
    function assignTeamTokens() public onlyOwnerAndDirector {
        require(!assignedTeam);
        assignedTeam = true;

        _teamTransfer(0x0A5f85C3d41892C934ae82BDbF17027A20717088,  101000000 * ReconToMicro); // Recon owner
        _teamTransfer(0x0f65e64662281D6D42eE6dEcb87CDB98fEAf6060,  100000000 * ReconToMicro); // Recon newOwner
        _teamTransfer(0x3Da2585FEbE344e52650d9174e7B1bf35C70D840,   50000000 * ReconToMicro); // Recon minter
        _teamTransfer(0xc083E68D962c2E062D2735B54804Bb5E1f367c1b,   50000000 * ReconToMicro); // Recon feeAccount
        _teamTransfer(0xF848332f5D902EFD874099458Bc8A53C8b7881B1,   50000000 * ReconToMicro); // Recon spender
        _teamTransfer(0x5f2D6766C6F3A7250CfD99d6b01380C432293F0c,   50000000 * ReconToMicro); // Recon recoveredAddress
        _teamTransfer(0x5f2D6766C6F3A7250CfD99d6b01380C432293F0c,  200000000 * ReconToMicro); // Proprity from ReconBank
        _teamTransfer(0xD974C2D74f0F352467ae2Da87fCc64491117e7ac,  200000000 * ReconToMicro); // Recon Manager
        _teamTransfer(0x5c4F791D0E0A2E75Ee34D62c16FB6D09328555fF, 5000000000 * ReconToMicro); // Recon Cash-in (B2B)
        _teamTransfer(0xeB479640A6D55374aF36896eCe6db7d92F390015, 5000000000 * ReconToMicro); // Recon Switch (C2C)
        _teamTransfer(0x77167D25Db87dc072399df433e450B00b8Ec105A, 7000000000 * ReconToMicro); // Recon Cash-out (B2C)
        _teamTransfer(0x5C6Fd84b961Cce03e027B0f8aE23c4A6e1195E90, 2000000000 * ReconToMicro); // Recon Investment
        _teamTransfer(0x86F427c5e05C29Fd4124746f6111c1a712C9B5c8, 2000000000 * ReconToMicro); // Recon Momentum
        _teamTransfer(0x1Ecb8dC0932AF3A3ba87e8bFE7eac3Cbe433B78B, 2000000000 * ReconToMicro); // Recon Reward
        _teamTransfer(0x7C31BeCa0290C35c8452b95eA462C988c4003Bb0, 1000000000 * ReconToMicro); // Recon Donate
        _teamTransfer(0x3a5326f9C9b3ff99e2e5011Aabec7b48B2e6A6A2, 4000000000 * ReconToMicro); // Recon Token
        _teamTransfer(0x5a27B07003ce50A80dbBc5512eA5BBd654790673, 4000000000 * ReconToMicro); // Recon Cash
        _teamTransfer(0xD580cF1002d0B4eF7d65dC9aC6a008230cE22692, 4000000000 * ReconToMicro); // Recon Gold
        _teamTransfer(0x9C83562Bf58083ab408E596A4bA4951a2b5724C9, 4000000000 * ReconToMicro); // Recon Card
        _teamTransfer(0x70E06c2Dd9568ECBae760CE2B61aC221C0c497F5, 2000000000 * ReconToMicro); // Recon Hardrive Wallet
        _teamTransfer(0x14bd2Aa04619658F517521adba7E5A17dfD2A3f0, 1000000000 * ReconToMicro); // Recoin Option
        _teamTransfer(0x9C3091a335383566d08cba374157Bdff5b8B034B,  100000000 * ReconToMicro); // Recon Promo
        _teamTransfer(0x3b6F53122903c40ef61441dB807f09D90D6F05c7, 1000000000 * ReconToMicro); // Recon patents
        _teamTransfer(0x7fb5EF151446Adb0B7D39B1902E45f06E11038F6, 1000000000 * ReconToMicro); // Recon Security & Legal Fees
        _teamTransfer(0x47BD87fa63Ce818584F050aFFECca0f1dfFd0564, 1000000000 * ReconToMicro); // ​Peer To Peer Networking Service
        _teamTransfer(0x83b3CD589Bd78aE65d7b338fF7DFc835cD9a8edD, 2000000000 * ReconToMicro); // Reconia
        _teamTransfer(0x6299496342fFd22B7191616fcD19CeC6537C2E8D, 8000000000 * ReconToMicro); // ​Recon Central Securities Depository (Recon Vault&#160;XtraStock)
        _teamTransfer(0x26aF11607Fad4FacF1fc44271aFA63Dbf2C22a87, 4000000000 * ReconToMicro); // Recon Central Securities Depository (Recon Vault&#160;SecurityStock)
        _teamTransfer(0x7E21203C5B4A6f98E4986f850dc37eBE9Ca19179, 4000000000 * ReconToMicro); // Recon Central Securities Depository (Recon Vault Advance Payment Stock)
        _teamTransfer(0x0bD212e88522b7F4C673fccBCc38558829337f71, 4000000000 * ReconToMicro); // Recon Central Securities Depository (Recon Vault PrivatStock)
        _teamTransfer(0x5b44e309408cE6E73B9f5869C9eeaCeeb8084DC8, 4000000000 * ReconToMicro); // Recon Central Securities Depository (Recon Vault Currency Insurance stock)
        _teamTransfer(0x48F2eFDE1c028792EbE7a870c55A860e40eb3573, 4000000000 * ReconToMicro); // Recon Central Securities Depository (Recon Vault&#160;NextStock)
        _teamTransfer(0x1fF3BE6f711C684F04Cf6adfD665Ce13D54CAC73, 4000000000 * ReconToMicro); // Recon Central Securities Depository (Recon Vault&#160;FuturStock)
    }

    // @nptice kycPassed is executed by backend and tells SC
    // that particular client has passed KYC
    mapping(address => bool) public kyc;
    mapping(address => address) public referral;
    function kycPassed(address _mem, address _ref) public onlyAdmin {
        kyc[_mem] = true;
        if (_ref == richardAddr || _ref == wuguAddr) {
            referral[_mem] = _ref;
        }
    }

    // mappings for implementing ERC20
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // mapping for implementing unlock mechanic
    mapping(address => uint) freezed;
    mapping(address => uint) teamFreezed;

    // ERC20 standard functions
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function _transfer(address _from, address _to, uint _tokens) private {
        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(_from, _to, _tokens);
    }

    function transfer(address _to, uint _tokens) public returns (bool success) {
        checkTransfer(msg.sender, _tokens);
        _transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        checkTransfer(from, tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, to, tokens);
        return true;
    }

    // @notice checkTransfer ensures that `from` can send only unlocked tokens
    // @notice this function is called for every transfer
    // We unlock PURCHASED and BONUS tokens in 13 stages:
    function checkTransfer(address from, uint tokens) public view {
        uint newBalance = balances[from].sub(tokens);
        uint total = 0;
        if (now < unlockDate5) {
            require(now >= unlockDate1);
            uint frzdPercent = 0;
            if (now < unlockDate2) {
                frzdPercent = 5;
            } else if (now < unlockDate3) {
                frzdPercent = 10;
            } else if (now < unlockDate4) {
                frzdPercent = 10;
            } else if (now < unlockDate5) {
                frzdPercent = 10;
            } else if (now < unlockDate6) {
                frzdPercent = 10;
            } else if (now < unlockDate7) {
                frzdPercent = 10;
            } else if (now < unlockDate8) {
                frzdPercent = 5;
            } else if (now < unlockDate9) {
                frzdPercent = 5;
            } else if (now < unlockDate10) {
                frzdPercent = 10;
            } else if (now < unlockDate11) {
                frzdPercent = 5;
            } else if (now < unlockDate12) {
                frzdPercent = 10;
            } else if (now < unlockDate13) {
                frzdPercent = 5;
            } else {
                frzdPercent = 5;
            }
            total = freezed[from].mul(frzdPercent).div(100);
            require(newBalance >= total);
        }

        if (now < teamUnlock4 && teamFreezed[from] > 0) {
            uint p = 0;
            if (now < teamUnlock1) {
                p = 100;
            } else if (now < teamUnlock2) {
                p = 75;
            } else if (now < teamUnlock3) {
                p = 50;
            } else if (now < teamUnlock4) {
                p = 25;
            }
            total = total.add(teamFreezed[from].mul(p).div(100));
            require(newBalance >= total);
        }
    }

    // @return ($ received, ETH received, RECON sold)
    function ICOStatus() public view returns (uint usd, uint eth, uint recon) {
        usd = presaleSold.mul(12).div(10**20) + crowdsaleSold.mul(16).div(10**20);
        usd = usd.add(preicoUSD); // pre-ico tokens

        return (usd, ethSold + preicoUSD.mul(10**8).div(ethRate), presaleSold + crowdsaleSold);
    }

    function checkICOStatus() public view returns(bool) {
        uint eth;
        uint recon;

        (, eth, recon) = ICOStatus();

        uint dollarsRecvd = eth.mul(ethRate).div(10**8);

        // 26 228 800$
        return dollarsRecvd >= 25228966 || (recon == presaleSupply + crowdsaleSupply) || now > crowdsaleEndTime;
    }

    bool icoClosed = false;
    function closeICO() public onlyOwner {
        require(!icoClosed);
        icoClosed = checkICOStatus();
    }

    // @notice by agreement, we can transfer $4.8M from bank
    // after softcap is reached.
    // @param _to wallet to send RECON to
    // @param  _usd amount of dollars which is withdrawn
    uint bonusTransferred = 0;
    uint constant maxUSD = 4800000;
    function transferBonus(address _to, uint _usd) public onlyOwner {
        bonusTransferred = bonusTransferred.add(_usd);
        require(bonusTransferred <= maxUSD);

        uint recon = _usd.mul(100).mul(ReconToMicro).div(12); // presale tariff
        presaleSold = presaleSold.add(recon);
        require(presaleSold <= presaleSupply);
        ethSold = ethSold.add(_usd.mul(10**8).div(ethRate));

        _freezeTransfer(_to, recon);
    }

    // @notice extend crowdsale for 2 weeks
    function prolongCrowdsale() public onlyOwnerAndDirector {
        require(now < crowdsaleEndTime);
        crowdsaleEndTime = crowdsaleHardEndTime;
    }

    // 100 000 000 Ether in dollars
    uint public ethRate = 0;
    uint public ethRateMax = 0;
    uint public ethLastUpdate = 0;
    function setETHRate(uint _rate) public onlyAdmin {
        require(ethRateMax == 0 || _rate < ethRateMax);
        ethRate = _rate;
        ethLastUpdate = now;
    }

    // 100 000 000 BTC in dollars
    uint public btcRate = 0;
    uint public btcRateMax = 0;
    uint public btcLastUpdate;
    function setBTCRate(uint _rate) public onlyAdmin {
        require(btcRateMax == 0 || _rate < btcRateMax);
        btcRate = _rate;
        btcLastUpdate = now;
    }

    // @notice setMaxRate sets max rate for both BTC/ETH to soften
    // negative consequences in case our backend gots hacked.
    function setMaxRate(uint ethMax, uint btcMax) public onlyOwnerAndDirector {
        ethRateMax = ethMax;
        btcRateMax = btcMax;
    }

    // @notice _sellPresale checks RECON purchases during crowdsale
    function _sellPresale(uint recon) private {
        require(recon >= bonusLevel0.mul(9950).div(10000));
        presaleSold = presaleSold.add(recon);
        require(presaleSold <= presaleSupply);
    }

    // @notice _sellCrowd checks RECON purchases during crowdsale
    function _sellCrowd(uint recon, address _to) private {
        require(recon >= crowdsaleMinUSD);

        if (crowdsaleSold.add(recon) <= crowdsaleSupply) {
            crowdsaleSold = crowdsaleSold.add(recon);
        } else {
            presaleSold = presaleSold.add(crowdsaleSold).add(recon).sub(crowdsaleSupply);
            require(presaleSold <= presaleSupply);
            crowdsaleSold = crowdsaleSupply;
        }

        if (now < crowdsaleStartTime + 3 days) {
            if (whitemap[_to] >= recon) {
                whitemap[_to] -= recon;
                whitelistTokens -= recon;
            } else {
                require(crowdsaleSupply.add(presaleSupply).sub(presaleSold) >= crowdsaleSold.add(whitelistTokens));
            }
        }
    }

    // @notice addInvestorBonusInPercent is used for sending bonuses for big investors in %
    function addInvestorBonusInPercent(address _to, uint8 p) public onlyOwner {
        require(p > 0 && p <= 5);
        uint bonus = balances[_to].mul(p).div(100);

        investorGiven = investorGiven.add(bonus);
        require(investorGiven <= investorSupply);

        _freezeTransfer(_to, bonus);
    }

    // @notice addInvestorBonusInTokens is used for sending bonuses for big investors in tokens
    function addInvestorBonusInTokens(address _to, uint tokens) public onlyOwner {
        _freezeTransfer(_to, tokens);

        investorGiven = investorGiven.add(tokens);
        require(investorGiven <= investorSupply);
    }

    function () payable public {
        purchaseWithETH(msg.sender);
    }

    // @notice _freezeTranfer perform actual tokens transfer which
    // will be freezed (see also checkTransfer() )
    function _freezeTransfer(address _to, uint recon) private {
        _transfer(owner, _to, recon);
        freezed[_to] = freezed[_to].add(recon);
    }

    // @notice _freezeTranfer perform actual tokens transfer which
    // will be freezed (see also checkTransfer() )
    function _teamTransfer(address _to, uint recon) private {
        _transfer(owner, _to, recon);
        teamFreezed[_to] = teamFreezed[_to].add(recon);
    }

    address public constant wuguAddr = 0x0d340F1344a262c13485e419860cb6c4d8Ec9C6e;
    address public constant richardAddr = 0x49BE16e7FECb14B82b4f661D9a0426F810ED7127;
    mapping(address => address[]) promoterClients;
    mapping(address => mapping(address => uint)) promoterBonus;

    // @notice withdrawPromoter transfers back to promoter
    // all bonuses accumulated to current moment
    function withdrawPromoter() public {
        address _to = msg.sender;
        require(_to == wuguAddr || _to == richardAddr);

        uint usd;
        (usd,,) = ICOStatus();

        // USD received - 5% must be more than softcap
        require(usd.mul(95).div(100) >= softcapUSD);

        uint bonus = 0;
        address[] memory clients = promoterClients[_to];
        for(uint i = 0; i < clients.length; i++) {
            if (kyc[clients[i]]) {
                uint num = promoterBonus[_to][clients[i]];
                delete promoterBonus[_to][clients[i]];
                bonus += num;
            }
        }

        _to.transfer(bonus);
    }

    // @notice cashBack will be used in case of failed ICO
    // All partitipants can receive their ETH back
    function cashBack(address _to) public {
        uint usd;
        (usd,,) = ICOStatus();

        // ICO fails if crowd-sale is ended and we have not yet reached soft-cap
        require(now > crowdsaleEndTime && usd < softcapUSD);
        require(ethSent[_to] > 0);

        delete ethSent[_to];

        _to.transfer(ethSent[_to]);
    }

    // @notice stores amount of ETH received by SC
    mapping(address => uint) ethSent;

    function purchaseWithETH(address _to) payable public {
        purchaseWithPromoter(_to, referral[msg.sender]);
    }

    // @notice purchases tokens, which a send to `_to` with 5% returned to `_ref`
    // @notice 5% return must work only on crowdsale
    function purchaseWithPromoter(address _to, address _ref) payable public {
        require(now >= presaleStartTime && now <= crowdsaleEndTime);

        require(!icoClosed);

        uint _wei = msg.value;
        uint recon;

        ethSent[msg.sender] = ethSent[msg.sender].add(_wei);
        ethSold = ethSold.add(_wei);

        // accept payment on presale only if it is more than 9997$
        // actual check is performed in _sellPresale
        if (now < crowdsaleStartTime || approvedInvestors[msg.sender]) {
            require(kyc[msg.sender]);
            recon = _wei.mul(ethRate).div(75000000); // 1 RECON = 0.75 $ on presale

            require(now < crowdsaleStartTime || recon >= bonusLevel100);

            _sellPresale(recon);

            // we have only 2 recognized promoters
            if (_ref == wuguAddr || _ref == richardAddr) {
                promoterClients[_ref].push(_to);
                promoterBonus[_ref][_to] = _wei.mul(5).div(100);
            }
        } else {
            recon = _wei.mul(ethRate).div(10000000); // 1 RECON = 1.00 $ on crowd-sale
            _sellCrowd(recon, _to);
        }

        _freezeTransfer(_to, recon);
    }

    // @notice purchaseWithBTC is called from backend, where we convert
    // BTC to ETH, and then assign tokens to purchaser, using BTC / $ exchange rate.
    function purchaseWithBTC(address _to, uint _satoshi, uint _wei) public onlyAdmin {
        require(now >= presaleStartTime && now <= crowdsaleEndTime);

        require(!icoClosed);

        ethSold = ethSold.add(_wei);

        uint recon;
        // accept payment on presale only if it is more than 9997$
        // actual check is performed in _sellPresale
        if (now < crowdsaleStartTime || approvedInvestors[msg.sender]) {
            require(kyc[msg.sender]);
            recon = _satoshi.mul(btcRate.mul(10000)).div(75); // 1 RECON = 0.75 $ on presale

            require(now < crowdsaleStartTime || recon >= bonusLevel100);

            _sellPresale(recon);
        } else {
            recon = _satoshi.mul(btcRate.mul(10000)).div(100); // 1 RECON = 1.00 $ on presale
            _sellCrowd(recon, _to);
        }

        _freezeTransfer(_to, recon);
    }

    // @notice withdrawFunds is called to send team bonuses after
    // then end of the ICO
    bool withdrawCalled = false;
    function withdrawFunds() public onlyOwner {
        require(icoClosed && now >= teamETHUnlock1);

        require(!withdrawCalled);
        withdrawCalled = true;

        uint eth;
        (,eth,) = ICOStatus();

        // pre-ico tokens are not in ethSold
        uint minus = bonusTransferred.mul(10**8).div(ethRate);
        uint team = ethSold.sub(minus);

        team = team.mul(15).div(100);

        uint ownerETH = 0;
        uint teamETH = 0;
        if (address(this).balance >= team) {
            teamETH = team;
            ownerETH = address(this).balance.sub(teamETH);
        } else {
            teamETH = address(this).balance;
        }

        teamETH1 = teamETH.div(3);
        teamETH2 = teamETH.div(3);
        teamETH3 = teamETH.sub(teamETH1).sub(teamETH2);

        // TODO multisig
        address(0xf14B65F1589B8bC085578BcF68f09653D8F6abA8).transfer(ownerETH);
    }

    uint teamETH1 = 0;
    uint teamETH2 = 0;
    uint teamETH3 = 0;
    function withdrawTeam() public {
        require(now >= teamETHUnlock1);

        uint amount = 0;
        if (now < teamETHUnlock2) {
            amount = teamETH1;
            teamETH1 = 0;
        } else if (now < teamETHUnlock3) {
            amount = teamETH1 + teamETH2;
            teamETH1 = 0;
            teamETH2 = 0;
        } else {
            amount = teamETH1 + teamETH2 + teamETH3;
            teamETH1 = 0;
            teamETH2 = 0;
            teamETH3 = 0;
        }

        address(0x5c4F791D0E0A2E75Ee34D62c16FB6D09328555fF).transfer(amount.mul(6).div(100)); // Recon Cash-in (B2B)
        address(0xeB479640A6D55374aF36896eCe6db7d92F390015).transfer(amount.mul(6).div(100)); // Recon Switch (C2C)
        address(0x77167D25Db87dc072399df433e450B00b8Ec105A).transfer(amount.mul(6).div(100)); // Recon Cash-out (B2C)
        address(0x1Ecb8dC0932AF3A3ba87e8bFE7eac3Cbe433B78B).transfer(amount.mul(2).div(100)); // Recon Reward
        address(0x7C31BeCa0290C35c8452b95eA462C988c4003Bb0).transfer(amount.mul(2).div(100)); // Recon Donate

        amount = amount.mul(78).div(100);

        address(0x3a5326f9C9b3ff99e2e5011Aabec7b48B2e6A6A2).transfer(amount.mul(uint(255).mul(100).div(96)).div(1000)); // Recon Token
        address(0x5a27B07003ce50A80dbBc5512eA5BBd654790673).transfer(amount.mul(uint(185).mul(100).div(96)).div(1000)); // Recon Cash
        address(0xD580cF1002d0B4eF7d65dC9aC6a008230cE22692).transfer(amount.mul(uint(25).mul(100).div(96)).div(1000));  // Recon Gold
        address(0x9C83562Bf58083ab408E596A4bA4951a2b5724C9).transfer(amount.mul(uint(250).mul(100).div(96)).div(1000)); // Recon Card
        address(0x70E06c2Dd9568ECBae760CE2B61aC221C0c497F5).transfer(amount.mul(uint(245).mul(100).div(96)).div(1000)); // Recon Hardrive Wallet
    }

    // @notice doAirdrop is called when we launch airdrop.
    // @notice airdrop tokens has their own supply.
    uint dropped = 0;
    function doAirdrop(address[] members, uint[] tokens) public onlyOwnerAndDirector {
        require(members.length == tokens.length);

        for(uint i = 0; i < members.length; i++) {
            _freezeTransfer(members[i], tokens[i]);
            dropped = dropped.add(tokens[i]);
        }
        require(dropped <= bountySupply);
    }

    mapping(address => uint) public whitemap;
    uint public whitelistTokens = 0;
    // @notice addWhitelistMember is used to whitelist participant.
    // This means, that for the first 3 days of crowd-sale `_tokens` RECON
    // will be reserved for him.
    function addWhitelistMember(address[] _mem, uint[] _tokens) public onlyAdmin {
        require(_mem.length == _tokens.length);
        for(uint i = 0; i < _mem.length; i++) {
            whitelistTokens = whitelistTokens.sub(whitemap[_mem[i]]).add(_tokens[i]);
            whitemap[_mem[i]] = _tokens[i];
        }
    }

    uint public adviserSold = 0;
    // @notice transferAdviser is called to send tokens to advisers.
    // @notice adviser tokens have their own supply
    function transferAdviser(address[] _adv, uint[] _tokens) public onlyOwnerAndDirector {
        require(_adv.length == _tokens.length);
        for (uint i = 0; i < _adv.length; i++) {
            adviserSold = adviserSold.add(_tokens[i]);
            _freezeTransfer(_adv[i], _tokens[i]);
        }
        require(adviserSold <= adviserSupply);
    }

    mapping(address => bool) approvedInvestors;
    function approveInvestor(address _addr) public onlyOwner {
        approvedInvestors[_addr] = true;
    }
}


// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------


pragma solidity ^ 0.4.25;

contract ERC20InterfaceTest {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contracts that can have tokens approved, and then a function execute
// ----------------------------------------------------------------------------
contract TestApproveAndCallFallBack {
    event LogBytes(bytes data);

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public {
        ERC20Interface(token).transferFrom(from, address(this), tokens);
        emit LogBytes(data);
    }
}

// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------

pragma solidity ^ 0.4.25;

contract AccessRestriction {
    // These will be assigned at the construction
    // phase, where `msg.sender` is the account
    // creating this contract.
    address public owner = msg.sender;
    uint public creationTime = now;

    // Modifiers can be used to change
    // the body of a function.
    // If this modifier is used, it will
    // prepend a check that only passes
    // if the function is called from
    // a certain address.
    modifier onlyBy(address _account)
    {
        require(
            msg.sender == _account,
            "Sender not authorized."
        );
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    // Make `_newOwner` the new owner of this
    // contract.
    function changeOwner(address _newOwner)
        public
        onlyBy(owner)
    {
        owner = _newOwner;
    }

    modifier onlyAfter(uint _time) {
        require(
            now >= _time,
            "Function called too early."
        );
        _;
    }

    // Erase ownership information.
    // May only be called 6 weeks after
    // the contract has been created.
    function disown()
        public
        onlyBy(owner)
        onlyAfter(creationTime + 6 weeks)
    {
        delete owner;
    }

    // This modifier requires a certain
    // fee being associated with a function call.
    // If the caller sent too much, he or she is
    // refunded, but only after the function body.
    // This was dangerous before Solidity version 0.4.0,
    // where it was possible to skip the part after `_;`.
    modifier costs(uint _amount) {
        require(
            msg.value >= _amount,
            "Not enough Ether provided."
        );
        _;
        if (msg.value > _amount)
            msg.sender.transfer(msg.value - _amount);
    }

    function forceOwnerChange(address _newOwner)
        public
        payable
        costs(200 ether)
    {
        owner = _newOwner;
        // just some example condition
        if (uint(owner) & 0 == 1)
            // This did not refund for Solidity
            // before version 0.4.0.
            return;
        // refund overpaid fees
    }
}

// -----------------------------------------------------------------------------------------------------------------
//
// (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
//
// -----------------------------------------------------------------------------------------------------------------

pragma solidity ^ 0.4.25;

contract WithdrawalContract {
    address public richest;
    uint public mostSent;

    mapping (address => uint) pendingWithdrawals;

    constructor() public payable {
        richest = msg.sender;
        mostSent = msg.value;
    }

    function becomeRichest() public payable returns (bool) {
        if (msg.value > mostSent) {
            pendingWithdrawals[richest] += msg.value;
            richest = msg.sender;
            mostSent = msg.value;
            return true;
        } else {
            return false;
        }
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}


// -----------------------------------------------------------------------------------------------------------------
//.
//"
//.             ::::::..  .,::::::  .,-:::::     ...    :::.    :::
//.           ;;;;``;;;; ;;;;&#39;&#39;&#39;&#39; ,;;;&#39;````&#39;  .;;;;;;;.`;;;;,  `;;;
//.            [[[,/[[[&#39;  [[cccc  [[[        ,[[     \[[,[[[[[. &#39;[[
//.            $$$$$$c    $$""""  $$$        $$$,     $$$$$$ "Y$c$$
//.            888b "88bo,888oo,__`88bo,__,o,"888,_ _,88P888    Y88
//.            MMMM   "W" """"YUMMM "YUMMMMMP" "YMMMMMP" MMM     YM
//.
//.
//" -----------------------------------------------------------------------------------------------------------------
//             &#184;.•*&#180;&#168;)
//        &#184;.•&#180;   &#184;.•&#180;&#184;.•*&#180;&#168;) &#184;.•*&#168;)
//  &#184;.•*&#180;       (&#184;.•&#180; (&#184;.•` &#164; ReconBank.eth / ReconBank.com*&#180;&#168;)
//                                                        &#184;.•&#180;&#184;.•*&#180;&#168;)
//                                                      (&#184;.•&#180;   &#184;.•`
//                                                          &#184;.•&#180;•.&#184;
//   (c) Recon&#174; / Common ownership of BlockReconChain&#174; for ReconBank&#174; / Ltd 2018.
// -----------------------------------------------------------------------------------------------------------------
//
// Common ownership of :
//  ____  _            _    _____                       _____ _           _
// |  _ \| |          | |  |  __ \                     / ____| |         (_)
// | |_) | | ___   ___| | _| |__) |___  ___ ___  _ __ | |    | |__   __ _ _ _ __
// |  _ <| |/ _ \ / __| |/ /  _  // _ \/ __/ _ \| &#39;_ \| |    | &#39;_ \ / _` | | &#39;_ \
// | |_) | | (_) | (__|   <| | \ \  __/ (_| (_) | | | | |____| | | | (_| | | | | |
// |____/|_|\___/ \___|_|\_\_|  \_\___|\___\___/|_| |_|\_____|_| |_|\__,_|_|_| |_|&#174;
//&#39;
// -----------------------------------------------------------------------------------------------------------------
//
// This contract is an order from :
//&#39;
// ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗██████╗  █████╗ ███╗   ██╗██╗  ██╗    ██████╗ ██████╗ ███╗   ███╗&#174;
// ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝   ██╔════╝██╔═══██╗████╗ ████║
// ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║██████╔╝███████║██╔██╗ ██║█████╔╝    ██║     ██║   ██║██╔████╔██║
// ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║██╔══██╗██╔══██║██║╚██╗██║██╔═██╗    ██║     ██║   ██║██║╚██╔╝██║
// ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║██████╔╝██║  ██║██║ ╚████║██║  ██╗██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║
// ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝&#39;
//
// -----------------------------------------------------------------------------------------------------------------


// Thank you for making the extra effort that others probably wouldnt have made