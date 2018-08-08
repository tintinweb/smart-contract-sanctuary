pragma solidity ^0.4.11;

// ==== DISCLAIMER ====
//
// ETHEREUM IS STILL AN EXPEREMENTAL TECHNOLOGY.
// ALTHOUGH THIS SMART CONTRACT WAS CREATED WITH GREAT CARE AND IN THE HOPE OF BEING USEFUL, NO GUARANTEES OF FLAWLESS OPERATION CAN BE GIVEN.
// IN PARTICULAR - SUBTILE BUGS, HACKER ATTACKS OR MALFUNCTION OF UNDERLYING TECHNOLOGY CAN CAUSE UNINTENTIONAL BEHAVIOUR.
// YOU ARE STRONGLY ENCOURAGED TO STUDY THIS SMART CONTRACT CAREFULLY IN ORDER TO UNDERSTAND POSSIBLE EDGE CASES AND RISKS.
// DON&#39;T USE THIS SMART CONTRACT IF YOU HAVE SUBSTANTIAL DOUBTS OR IF YOU DON&#39;T KNOW WHAT YOU ARE DOING.
//
// THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
// OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ====
//

/// @author Santiment Sagl
/// @title  CrowdsaleMinter

contract Base {

    function max(uint a, uint b) returns (uint) { return a >= b ? a : b; }
    function min(uint a, uint b) returns (uint) { return a <= b ? a : b; }

    modifier only(address allowed) {
        if (msg.sender != allowed) throw;
        _;
    }


    ///@return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns (bool) {
        if (_addr == 0) return false;
        uint size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    // *************************************************
    // *          reentrancy handling                  *
    // *************************************************

    //@dev predefined locks (up to uint bit length, i.e. 256 possible)
    uint constant internal L00 = 2 ** 0;
    uint constant internal L01 = 2 ** 1;
    uint constant internal L02 = 2 ** 2;
    uint constant internal L03 = 2 ** 3;
    uint constant internal L04 = 2 ** 4;
    uint constant internal L05 = 2 ** 5;

    //prevents reentrancy attacs: specific locks
    uint private bitlocks = 0;
    modifier noReentrancy(uint m) {
        var _locks = bitlocks;
        if (_locks & m > 0) throw;
        bitlocks |= m;
        _;
        bitlocks = _locks;
    }

    modifier noAnyReentrancy {
        var _locks = bitlocks;
        if (_locks > 0) throw;
        bitlocks = uint(-1);
        _;
        bitlocks = _locks;
    }

    ///@dev empty marking modifier signaling to user of the marked function , that it can cause an reentrant call.
    ///     developer should make the caller function reentrant-safe if it use a reentrant function.
    modifier reentrant { _; }

}

contract MintableToken {
    //target token contract is responsible to accept only authorized mint calls.
    function mint(uint amount, address account);

    //start the token on minting finished,
    function start();
}

contract Owned is Base {

    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

}

contract BalanceStorage {
    function balances(address account) public constant returns(uint balance);
}

contract AddressList {
    function contains(address addr) public constant returns (bool);
}

contract MinMaxWhiteList {
    function allowed(address addr) public constant returns (uint /*finney*/, uint /*finney*/ );
}

contract PresaleBonusVoting {
    function rawVotes(address addr) public constant returns (uint rawVote);
}

contract CrowdsaleMinter is Owned {

    string public constant VERSION = "0.2.1-TEST.MAX.1";

    /* ====== configuration START ====== */
    uint public constant COMMUNITY_SALE_START = 3969950; /* approx. 04.07.2017 00:30 */
    uint public constant PRIORITY_SALE_START  = 3970050; /* approx. 04.07.2017 01:00 */
    uint public constant PUBLIC_SALE_START    = 3970150; /* approx. 04.07.2017 01:30 */
    uint public constant PUBLIC_SALE_END      = 3970250; /* approx. 04.07.2017 02:00 */
    uint public constant WITHDRAWAL_END       = 3970350; /* approx. 04.07.2017 02:30 */

    address public TEAM_GROUP_WALLET           = 0x215aCB37845027cA64a4f29B2FCb7AffA8E9d326;
    address public ADVISERS_AND_FRIENDS_WALLET = 0x41ab8360dEF1e19FdFa32092D83a7a7996C312a4;

    uint public constant TEAM_BONUS_PER_CENT            = 18;
    uint public constant ADVISORS_AND_PARTNERS_PER_CENT = 10;

    MintableToken      public TOKEN                    = MintableToken(0x00000000000000000000000000);

    AddressList        public PRIORITY_ADDRESS_LIST    = AddressList(0x463635eFd22558c64Efa6227A45649eeDc0e4888);
    MinMaxWhiteList    public COMMUNITY_ALLOWANCE_LIST = MinMaxWhiteList(0x3375D3d9df8C67b3D7EBcE220c3DDa4BE03dCE31);
    BalanceStorage     public PRESALE_BALANCES         = BalanceStorage(0x4Fd997Ed7c10DbD04e95d3730cd77D79513076F2);
    PresaleBonusVoting public PRESALE_BONUS_VOTING     = PresaleBonusVoting(0x283a97Af867165169AECe0b2E963b9f0FC7E5b8c);

    uint public constant COMMUNITY_PLUS_PRIORITY_SALE_CAP_ETH = 4;
    uint public constant MIN_TOTAL_AMOUNT_TO_RECEIVE_ETH = 3;
    uint public constant MAX_TOTAL_AMOUNT_TO_RECEIVE_ETH = 5;
    uint public constant MIN_ACCEPTED_AMOUNT_FINNEY = 500;
    uint public constant TOKEN_PER_ETH = 1000;
    uint public constant PRE_SALE_BONUS_PER_CENT = 54;

    //constructor
    function CrowdsaleMinter() {
        //check configuration if something in setup is looking weird
        if (
            TOKEN_PER_ETH == 0
            || TEAM_BONUS_PER_CENT + ADVISORS_AND_PARTNERS_PER_CENT >=100
            || MIN_ACCEPTED_AMOUNT_FINNEY < 1
            || owner == 0x0
            || address(COMMUNITY_ALLOWANCE_LIST) == 0x0
            || address(PRIORITY_ADDRESS_LIST) == 0x0
            || address(PRESALE_BONUS_VOTING) == 0x0
            || address(PRESALE_BALANCES) == 0x0
            || COMMUNITY_SALE_START == 0
            || PRIORITY_SALE_START == 0
            || PUBLIC_SALE_START == 0
            || PUBLIC_SALE_END == 0
            || WITHDRAWAL_END == 0
            || MIN_TOTAL_AMOUNT_TO_RECEIVE == 0
            || MAX_TOTAL_AMOUNT_TO_RECEIVE == 0
            || COMMUNITY_PLUS_PRIORITY_SALE_CAP == 0
            || COMMUNITY_SALE_START <= block.number
            || COMMUNITY_SALE_START >= PRIORITY_SALE_START
            || PRIORITY_SALE_START >= PUBLIC_SALE_START
            || PUBLIC_SALE_START >= PUBLIC_SALE_END
            || PUBLIC_SALE_END >= WITHDRAWAL_END
            || COMMUNITY_PLUS_PRIORITY_SALE_CAP > MAX_TOTAL_AMOUNT_TO_RECEIVE
            || MIN_TOTAL_AMOUNT_TO_RECEIVE > MAX_TOTAL_AMOUNT_TO_RECEIVE )
        throw;
    }

    /* ====== configuration END ====== */

    /* ====== public states START====== */

    bool public isAborted = false;
    mapping (address => uint) public balances;
    bool public TOKEN_STARTED = false;
    uint public total_received_amount;
    address[] public investors;

    //displays number of uniq investors
    function investorsCount() constant external returns(uint) { return investors.length; }

    //displays received amount in eth upto now
    function TOTAL_RECEIVED_ETH() constant external returns (uint) { return total_received_amount / 1 ether; }

    //displays current contract state in human readable form
    function state() constant external returns (string) { return stateNames[ uint(currentState()) ]; }

    function san_whitelist(address addr) public constant returns(uint, uint) { return COMMUNITY_ALLOWANCE_LIST.allowed(addr); }
    function cfi_whitelist(address addr) public constant returns(bool) { return PRIORITY_ADDRESS_LIST.contains(addr); }

    /* ====== public states END ====== */

    string[] private stateNames = ["BEFORE_START", "COMMUNITY_SALE", "PRIORITY_SALE", "PRIORITY_SALE_FINISHED", "PUBLIC_SALE", "BONUS_MINTING", "WITHDRAWAL_RUNNING", "REFUND_RUNNING", "CLOSED" ];
    enum State { BEFORE_START, COMMUNITY_SALE, PRIORITY_SALE, PRIORITY_SALE_FINISHED, PUBLIC_SALE, BONUS_MINTING, WITHDRAWAL_RUNNING, REFUND_RUNNING, CLOSED }

    uint private constant COMMUNITY_PLUS_PRIORITY_SALE_CAP = COMMUNITY_PLUS_PRIORITY_SALE_CAP_ETH * 1 ether;
    uint private constant MIN_TOTAL_AMOUNT_TO_RECEIVE = MIN_TOTAL_AMOUNT_TO_RECEIVE_ETH * 1 ether;
    uint private constant MAX_TOTAL_AMOUNT_TO_RECEIVE = MAX_TOTAL_AMOUNT_TO_RECEIVE_ETH * 1 ether;
    uint private constant MIN_ACCEPTED_AMOUNT = MIN_ACCEPTED_AMOUNT_FINNEY * 1 finney;
    bool private allBonusesAreMinted = false;

    //
    // ======= interface methods =======
    //

    //accept payments here
    function ()
    payable
    noAnyReentrancy
    {
        State state = currentState();
        uint amount_allowed;
        if (state == State.COMMUNITY_SALE) {
            var (min_finney, max_finney) = COMMUNITY_ALLOWANCE_LIST.allowed(msg.sender);
            var (min, max) = (min_finney * 1 finney, max_finney * 1 finney);
            var sender_balance = balances[msg.sender];
            assert (sender_balance <= max); //sanity check: should be always true;
            assert (msg.value >= min);      //reject payments less than minimum
            amount_allowed = max - sender_balance;
            _receiveFundsUpTo(amount_allowed);
        } else if (state == State.PRIORITY_SALE) {
            assert (PRIORITY_ADDRESS_LIST.contains(msg.sender));
            amount_allowed = COMMUNITY_PLUS_PRIORITY_SALE_CAP - total_received_amount;
            _receiveFundsUpTo(amount_allowed);
        } else if (state == State.PUBLIC_SALE) {
            amount_allowed = MAX_TOTAL_AMOUNT_TO_RECEIVE - total_received_amount;
            _receiveFundsUpTo(amount_allowed);
        } else if (state == State.REFUND_RUNNING) {
            // any entring call in Refund Phase will cause full refund
            _sendRefund();
        } else {
            throw;
        }
    }


    function refund() external
    inState(State.REFUND_RUNNING)
    noAnyReentrancy
    {
        _sendRefund();
    }


    function withdrawFundsAndStartToken() external
    inState(State.WITHDRAWAL_RUNNING)
    noAnyReentrancy
    only(owner)
    {
        // transfer funds to owner
        if (!owner.send(this.balance)) throw;

        //notify token contract to start
        if (TOKEN.call(bytes4(sha3("start()")))) {
            TOKEN_STARTED = true;
            TokenStarted(TOKEN);
        }
    }

    event TokenStarted(address tokenAddr);

    //there are around 40 addresses in PRESALE_ADDRESSES list. Everything fits into single Tx.
    function mintAllBonuses() external
    inState(State.BONUS_MINTING)
    noAnyReentrancy
    {
        assert(!allBonusesAreMinted);
        allBonusesAreMinted = true;

        uint TEAM_AND_PARTNERS_PER_CENT = TEAM_BONUS_PER_CENT + ADVISORS_AND_PARTNERS_PER_CENT;

        uint total_presale_amount_with_bonus = mintPresaleBonuses();
        uint total_collected_amount = total_received_amount + total_presale_amount_with_bonus;
        uint extra_amount = total_collected_amount * TEAM_AND_PARTNERS_PER_CENT / (100 - TEAM_AND_PARTNERS_PER_CENT);
        uint extra_team_amount = extra_amount * TEAM_BONUS_PER_CENT / TEAM_AND_PARTNERS_PER_CENT;
        uint extra_partners_amount = extra_amount * ADVISORS_AND_PARTNERS_PER_CENT / TEAM_AND_PARTNERS_PER_CENT;
/* 
        //beautify total supply: round down to full eth.
        uint total_to_mint = total_collected_amount + extra_amount;
        uint round_remainder = total_to_mint - (total_to_mint / 1 ether * 1 ether);
        extra_team_amount -= round_remainder; //this will reduce total_supply to rounded value
*/
        //mint group bonuses
        _mint(extra_team_amount , TEAM_GROUP_WALLET);
        _mint(extra_partners_amount, ADVISERS_AND_FRIENDS_WALLET);

    }

    function mintPresaleBonuses() internal returns(uint amount) {
        uint total_presale_amount_with_bonus = 0;
        //mint presale bonuses
        for(uint i=0; i < PRESALE_ADDRESSES.length; ++i) {
            address addr = PRESALE_ADDRESSES[i];
            var amount_with_bonus = presaleTokenAmount(addr);
            if (amount_with_bonus>0) {
                _mint(amount_with_bonus, addr);
                total_presale_amount_with_bonus += amount_with_bonus;
            }
        }//for
        return total_presale_amount_with_bonus;
    }

    function presaleTokenAmount(address addr) public constant returns(uint){
        uint presale_balance = PRESALE_BALANCES.balances(addr);
        if (presale_balance > 0) {
            // this calculation is about waived pre-sale bonus.
            // rawVote contains a value [0..1 ether].
            //     0 ether    - means "default value" or "no vote" : 100% bonus saved
            //     1 ether    - means "vote 100%" : 100% bonus saved
            //    <=10 finney - special value "vote 0%" : no bonus at all (100% bonus waived).
            //  other value - "PRE_SALE_BONUS_PER_CENT * rawVote / 1 ether" is an effective bonus per cent for particular presale member.
            //
            var rawVote = PRESALE_BONUS_VOTING.rawVotes(addr);
            if (rawVote == 0)              rawVote = 1 ether; //special case "no vote" (default value) ==> (1 ether is 100%)
            else if (rawVote <= 10 finney) rawVote = 0;       //special case "0%" (no bonus)           ==> (0 ether is   0%)
            else if (rawVote > 1 ether)    rawVote = 1 ether; //max bonus is 100% (should not occur)
            var presale_bonus = presale_balance * PRE_SALE_BONUS_PER_CENT * rawVote / 1 ether / 100;
            return presale_balance + presale_bonus;
        } else {
            return 0;
        }
    }

    function attachToToken(MintableToken tokenAddr) external
    inState(State.BEFORE_START)
    only(owner)
    {
        TOKEN = tokenAddr;
    }

    function abort() external
    inStateBefore(State.REFUND_RUNNING)
    only(owner)
    {
        isAborted = true;
    }

    //
    // ======= implementation methods =======
    //

    function _sendRefund() private
    tokenHoldersOnly
    {
        // load balance to refund plus amount currently sent
        var amount_to_refund = balances[msg.sender] + msg.value;
        // reset balance
        balances[msg.sender] = 0;
        // send refund back to sender
        if (!msg.sender.send(amount_to_refund)) throw;
    }

    function _receiveFundsUpTo(uint amount) private
    notTooSmallAmountOnly
    {
        require (amount > 0);
        if (msg.value > amount) {
            // accept amount only and return change
            var change_to_return = msg.value - amount;
            if (!msg.sender.send(change_to_return)) throw;
        } else {
            // accept full amount
            amount = msg.value;
        }
        if (balances[msg.sender] == 0) investors.push(msg.sender);
        balances[msg.sender] += amount;
        total_received_amount += amount;
        _mint(amount,msg.sender);
    }

    function _mint(uint amount, address account) private {
        MintableToken(TOKEN).mint(amount * TOKEN_PER_ETH, account);
    }

    function currentState() private constant
    returns (State)
    {
        if (isAborted) {
            return this.balance > 0
                   ? State.REFUND_RUNNING
                   : State.CLOSED;
        } else if (block.number < COMMUNITY_SALE_START || address(TOKEN) == 0x0) {
             return State.BEFORE_START;
        } else if (block.number < PRIORITY_SALE_START) {
            return State.COMMUNITY_SALE;
        } else if (block.number < PUBLIC_SALE_START) {
            return total_received_amount < COMMUNITY_PLUS_PRIORITY_SALE_CAP
                ? State.PRIORITY_SALE
                : State.PRIORITY_SALE_FINISHED;
        } else if (block.number <= PUBLIC_SALE_END && total_received_amount < MAX_TOTAL_AMOUNT_TO_RECEIVE) {
            return State.PUBLIC_SALE;
        } else if (this.balance == 0) {
            return State.CLOSED;
        } else if (block.number <= WITHDRAWAL_END && total_received_amount >= MIN_TOTAL_AMOUNT_TO_RECEIVE) {
            return allBonusesAreMinted
                ? State.WITHDRAWAL_RUNNING
                : State.BONUS_MINTING;
        } else {
            return State.REFUND_RUNNING;
        }
    }

    //
    // ============ modifiers ============
    //

    //fails if state dosn&#39;t match
    modifier inState(State state) {
        if (state != currentState()) throw;
        _;
    }

    //fails if the current state is not before than the given one.
    modifier inStateBefore(State state) {
        if (currentState() >= state) throw;
        _;
    }

    //accepts calls from token holders only
    modifier tokenHoldersOnly(){
        if (balances[msg.sender] == 0) throw;
        _;
    }


    // don`t accept transactions with value less than allowed minimum
    modifier notTooSmallAmountOnly(){
        if (msg.value < MIN_ACCEPTED_AMOUNT) throw;
        _;
    }

    //
    // ============ DATA ============
    //

    address[] PRESALE_ADDRESSES = [
        0xF55DFd2B02Cf3282680C94BD01E9Da044044E6A2,
        0x0D40B53828948b340673674Ae65Ee7f5D8488e33,
        0x0ea690d466d6bbd18F124E204EA486a4Bf934cbA,
        0x6d25B9f40b92CcF158250625A152574603465192,
        0x481Da0F1e89c206712BCeA4f7D6E60d7b42f6C6C,
        0x416EDa5D6Ed29CAc3e6D97C102d61BC578C5dB87,
        0xD78Ac6FFc90E084F5fD563563Cc9fD33eE303f18,
        0xe6714ab523acEcf9b85d880492A2AcDBe4184892,
        0x285A9cA5fE9ee854457016a7a5d3A3BB95538093,
        0x600ca6372f312B081205B2C3dA72517a603a15Cc,
        0x2b8d5C9209fBD500Fd817D960830AC6718b88112,
        0x4B15Dd23E5f9062e4FB3a9B7DECF653C0215e560,
        0xD67449e6AB23c1f46dea77d3f5E5D47Ff33Dc9a9,
        0xd0ADaD7ed81AfDa039969566Ceb8423E0ab14d90,
        0x245f27796a44d7E3D30654eD62850ff09EE85656,
        0x639D6eC2cef4d6f7130b40132B3B6F5b667e5105,
        0x5e9a69B8656914965d69d8da49c3709F0bF2B5Ef,
        0x0832c3B801319b62aB1D3535615d1fe9aFc3397A,
        0xf6Dd631279377205818C3a6725EeEFB9D0F6b9F3,
        0x47696054e71e4c3f899119601a255a7065C3087B,
        0xf107bE6c6833f61A24c64D63c8A7fcD784Abff06,
        0x056f072Bd2240315b708DBCbDDE80d400f0394a1,
        0x9e5BaeC244D8cCD49477037E28ed70584EeAD956,
        0x40A0b2c1B4E30F27e21DF94e734671856b485966,
        0x84f0620A547a4D14A7987770c4F5C25d488d6335,
        0x036Ac11c161C09d94cA39F7B24C1bC82046c332B,
        0x2912A18C902dE6f95321D6d6305D7B80Eec4C055,
        0xE1Ad30971b83c17E2A24c0334CB45f808AbEBc87,
        0x07f35b7FE735c49FD5051D5a0C2e74c9177fEa6d,
        0x11669Cce6AF3ce1Ef3777721fCC0eef0eE57Eaba,
        0xBDbaF6434d40D6355B1e80e40Cc4AB9C68D96116,
        0x17125b59ac51cEe029E4bD78D7f5947D1eA49BB2,
        0xA382A3A65c3F8ee2b726A2535B3c34A89D9094D4,
        0xAB78c8781fB64Bed37B274C5EE759eE33465f1f3,
        0xE74F2062612E3cAE8a93E24b2f0D3a2133373884,
        0x505120957A9806827F8F111A123561E82C40bC78,
        0x00A46922B1C54Ae6b5818C49B97E03EB4BB352e1,
        0xE76fE52a251C8F3a5dcD657E47A6C8D16Fdf4bFA
    ];

}// CrowdsaleMinter