// SPDX-License-Identifier: MIT
pragma solidity ^0.6.9;

// After deploy and setup necessaries rules and addresses, need to change the Owner address to the GovernanceProxy address.
import "./Ownable.sol";
import "./EnumerableSet.sol";

interface IWhitelist {
    function address_belongs(address _who) external view returns (address);
    function getUserWallets(address _which) external view returns (address[] memory);
}

interface IERC20Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
}

// The GovernanceProxy contract address should be the Owner of other contracts which setting we will change.
interface IGovernanceProxy {
    function trigger(address contr, bytes calldata params) external;
    function acceptGovernanceAddress() external;
}

contract Governance is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet walletsCEO;    // wallets of CEO. It should participate in votes with Absolute majority, otherwise Escrowed wallets will not be counted.
    uint256 public requiredCEO;             // number COE wallets require to participate in vote

    IGovernanceProxy public governanceProxy;
    IERC20Token[4] public tokenContract; // tokenContract[0] = MainToken, tokenContract[1] = ETN, tokenContract[2] = STOCK
    IERC20Token[4] public escrowContract; // contract that hold (lock) investor's pre-minted tokens (0-Main, 1-ETN, 2-STOCK)
    uint256[4] public circulationSupply;   // Circulation Supply of according tokens
    uint256[4] public circulationSupplyUpdated; // timestamp when Circulation Supply was updated
    IWhitelist public whitelist;    // whitelist contract
    uint256 public closeTime;   // timestamp when votes will close
    uint256 public expeditedLevel = 10; // user who has this percentage of Main token circulation supply can expedite voting
    uint256 public absoluteLevel = 90; // this percentage of participants voting power considering as Absolute Majority

    enum Vote {None, Yea, Nay}
    enum Status {New, Canceled, Approved, Rejected, Pending}

    struct Rule {
        address contr;      // contract address which have to be triggered
        uint8[4] majority;  // require more than this percentage of participants voting power (in according tokens).
        string funcAbi;     // function ABI (ex. "setGroupBonusRatio(uint256)")
    }

    Rule[] rules;

    struct Ballot {
        uint256 closeVote; // timestamp when vote will close
        uint256 ruleId; // rule which edit
        bytes args; // ABI encoded arguments for proposal which is required to call appropriate function
        Status status;
        address creator;    // wallet address of ballot creator.
        uint256[4] votesYea;  // YEA votes according communities (tokens)
        uint256[4] totalVotes;  // The total voting power od all participant according communities (tokens)
        address[] participant;  // the users who voted (primary address)
        uint256 processedParticipants; // The number of participant that was verified. Uses to split verification on many transactions
        mapping (address => Vote) votes; //Vote: Yea or Nay. If None -the user did not vote.
        mapping (address => mapping (uint256 => uint256)) power;   // Voting power. primary address => community index => voting power
        uint256 ceoParticipate; //number of ceo wallets participated at voting
    }

    Ballot[] ballots;

    uint256 public unprocessedBallot; // The start index of ballots which are unprocessed and maybe ready for vote.

    mapping (address => bool) public blockedWallets;    // The wallets which are excluded from voting
    mapping (uint256 => mapping(address => bool)) public isInEscrow;    // The wallets which may has pre-minted tokens. Token index => wallet
    mapping (uint256 => address[]) excluded; // The list of address that should be subtracted from TotalSupply to calculate Circulation Supply.
                                             // ex. Company wallet, Downside protection, Vault smart contract.

    event AddRule(address indexed contractAddress, string funcAbi, uint8[4] majorMain);
    event SetNewAddress(address indexed previousAddress, address indexed newAddress);
    event BlockWallet(address indexed walletAddress, bool isAdded);
    event AddBallot(address indexed creator, uint256 indexed ruleId, uint256 indexed ballotId);
    event ExpeditedBallot(uint256 indexed ballotId, uint256 indexed closeTime);
    event ApplyBallot(uint256 indexed ruleId, uint256 indexed ballotId);
    event NewVote(address indexed voter, address indexed primary, uint256 indexed ballotId);
    event ChangeVote(address indexed voter, address indexed primary, uint256 indexed ballotId);
    event PosableMajority(uint256 indexed ballotId);
    event CEOWallet(address indexed wallet, bool add);

    /**
     * @dev Throws if called by any account other than the one of COE wallets.
     */
    modifier onlyCEO() {
        require(walletsCEO.contains(msg.sender),"Not CEO");
        _;
    }

    constructor(address CEO_wallet) public {
        require(CEO_wallet != address(0),"Zero address not allowed");
        // add rule with Absolute majority (above 90% participants) which allow to add another rules
        rules.push(Rule(address(this), [90,0,0,0], "addRule(address,uint8[4],string)"));
        walletsCEO.add(CEO_wallet);
        requiredCEO = 1;
    }


    function addCEOWallet(address CEO_wallet) external onlyCEO {
        require(CEO_wallet != address(0),"Zero address not allowed");
        walletsCEO.add(CEO_wallet);
        requiredCEO = walletsCEO.length();
        emit CEOWallet(CEO_wallet, true);
    }

    function removeCEOWallet(address CEO_wallet) external onlyCEO {
        require(CEO_wallet != address(0),"Zero address not allowed");
        require(walletsCEO.length() > 1, "Should left at least one CEO wallet");
        walletsCEO.remove(CEO_wallet);
        requiredCEO = walletsCEO.length();
        emit CEOWallet(CEO_wallet, false);
    }

    function setRequiredCEO(uint256 req) external onlyCEO {
        require(req <= walletsCEO.length(),"More then added wallets");
        requiredCEO = req;
    }

    function getWalletsCEO() external view returns(address[] memory wallets) {
        return walletsCEO._values;
    }

    /**
     * @dev Accept Governance in case changing voting contract.
     */    
    function acceptGovernanceAddress() external onlyOwner {
        governanceProxy.acceptGovernanceAddress();
    }

    /**
     * @dev Calculation Supply = Total Supply - Total balance on Excluded wallets.
     * @param index The index of token (0 - Main, 1 - ETN, 2 - STOCK).
     * @return list of excluded address.
     */
    function getExcluded(uint256 index) external view returns(address[] memory) {
        require(index >= 0 && index < 4, "Wrong index");
        return excluded[index];
    }

    /**
     * @dev Add addresses to excluded list
     * @param index The index of token (0 - Main, 1 - ETN, 2 - STOCK).
     * @param wallet List of addresses to add
     */
    function addExcluded(uint256 index, address[] memory wallet) external onlyOwner {
        require(index >= 0 && index < 4, "Wrong index");
        for (uint i = 0; i < wallet.length; i++) {
            require(wallet[i] != address(0),"Zero address not allowed");
            excluded[index].push(wallet[i]);
        }
    }

    /**
     * @dev Remove addresses from excluded list
     * @param index The index of token (0 - Main, 1 - ETN, 2 - STOCK).
     * @param wallet The address to remove
     */
    function removeExcluded(uint256 index, address wallet) external onlyOwner {
        require(index >= 0 && index < 4, "Wrong index");
        require(wallet != address(0),"Zero address not allowed");
        uint len = excluded[index].length;
        for (uint i = 0; i < len; i++) {
            if (excluded[index][i] == wallet) {
                excluded[index][i] = excluded[index][len-1];
                excluded[index].pop();
            }
        }
    }

    /**
     * @dev Set percentage of participants voting power considering as Absolute Majority
     * @param level The percentage
     */
    function setAbsoluteLevel(uint256 level) external onlyOwner {
        require(level > 50 && level <= 100, "Wrong level");
        absoluteLevel = level;
    }

    /**
     * @dev Set percentage of total circulation that allows user to expedite proposal
     * @param level The percentage
     */
    function setExpeditedLevel(uint256 level) external onlyOwner {
        require(level >= 1 && level <= 100, "Wrong level");
        expeditedLevel = level;
    }

    /**
     * @dev Add/Remove address from the list of wallets which is disallowed to vote.
     * @param wallet The address to add or remove.
     * @param add Add to the list if true (1) or remove from the list if false (0).
     */
    function manageBlockedWallet(address wallet, bool add) external onlyOwner {
        emit BlockWallet(wallet, add);
        blockedWallets[wallet] = add;
    }

    /**
     * @dev Set token contract address.
     * @param token The address of token contract.
     * @param index The index of token: 0 - Main, 1 - ETN, 2 - STOCK.
     */
    function setTokenContract(IERC20Token token, uint index) external onlyOwner {
        require(token != IERC20Token(0) && tokenContract[index] == IERC20Token(0),"Change address not allowed");
        tokenContract[index] = token;
    }

    /**
     * @dev Set Escrow contract address, where pre-minted tokens locked (index of token: 0 - Main, 1 - ETN, 2 - STOCK).
     * @param escrow The address of token contract.
     * @param index The index of token: 0 - Main, 1 - ETN, 2 - STOCK.
     */
    function setEscrowContract(IERC20Token escrow, uint index) external onlyOwner {
        require(escrow != IERC20Token(0),"Change address not allowed");
        escrowContract[index] = escrow;
    }

    /**
     * @dev Set whitelist contract address to a newAddr.
     * @param newAddr The address of whitelist contract.
     */
    function setWhitelist(address newAddr) external onlyOwner {
        require(newAddr != address(0),"Zero address not allowed");
        emit SetNewAddress(address(whitelist), newAddr);
        whitelist = IWhitelist(newAddr);
    }

    /**
     * @dev Set Governance Proxy contract address to a newAddr.
     * @param newAddr The address of Governance Proxy contract.
     */
    function setGovernanceProxy(address newAddr) external onlyOwner {
        require(newAddr != address(0),"Zero address not allowed");
        emit SetNewAddress(address(governanceProxy), newAddr);
        governanceProxy = IGovernanceProxy(newAddr);
    }

    /**
     * @dev Update time when new votes will close. Should be called after 00:00:00 UTC 1st day of each month
     */
    function updateCloseTime() external {
        require(closeTime < block.timestamp, "Wait for 1st day of month"); // close time is not passed
        (uint year, uint month, uint day) = timestampToDate(block.timestamp);
        day = 1;
        if (month == 12) {
            year++;
            month = 1;
        }
        else {
            month++;
        }
        closeTime = timestampFromDateTime(year, month, day, 0, 0, 0);    // 1st day of each month at 00:00:00 UTC
        uint len = ballots.length;
        for (uint i = unprocessedBallot; i < len; i++) {
            if (ballots[i].status == Status.Pending) {
                if(ballots[i].closeVote == 0)
                    ballots[i].closeVote = closeTime;
                else
                    ballots[i].closeVote += closeTime; // Expedited vote
                ballots[i].status = Status.New;
            }
        }
    }

    /**
     * @dev Add wallet that received pre-minted tokens.
     * @param wallet The address of wallet.
     * @return true if address added.
     */
    function addPremintedWallet(address wallet) external returns(bool){
        for (uint i = 0; i < 4; i++ ) {
            if(address(escrowContract[i]) == msg.sender) {
                isInEscrow[i][wallet] = true;
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Add new rule - function that call target contract to change setting.
     * @param contr The contract address which have to be triggered
     * @param majority The majority level (%) for the tokens (index: 0 - Main, 1 - ETN, 2 - STOCK).
     * @param funcAbi The function ABI (ex. "setGroupBonusRatio(uint256)")
     */
    function addRule(
            address contr,
            uint8[4] memory majority,
            string memory funcAbi
        ) external onlyOwner {
        require(contr != address(0), "Zero address");
        rules.push(Rule(contr, majority, funcAbi));
        emit AddRule(contr, funcAbi, majority);
    }

    /**
     * @dev Change majority levels of rules.
     * @param ruleId The rules index
     * @param majority The majority level (%) for the tokens (index: 0 - Main, 1 - ETN, 2 - STOCK).
     */
    function changeRuleMajority(uint256 ruleId, uint8[4] memory majority) external onlyOwner {
        Rule storage r = rules[ruleId];
        r.majority = majority;
    }

    /**
     * @dev Change destination contract address of rules.
     * @param ruleId The rules index
     * @param contr The new contract address of selected rule.
     */
    function changeRuleAddress(uint256 ruleId, address contr) external onlyOwner {
        require(contr != address(0), "Zero address");
        Rule storage r = rules[ruleId];
        r.contr = contr;
    }

    /**
     * @dev Get total number of rules.
     * @return The total number of rules.
     */
    function getTotalRules() external view returns(uint256) {
        return rules.length;
    }

    /**
     * @dev Get rules details.
     * @param ruleId The rules index
     * @return contr The contract address
     * @return majority The level of majority in according tokens
     * @return funcAbi The function Abi
     */
    function getRule(uint256 ruleId) external view
        returns(address contr,
        uint8[4] memory majority,
        string memory funcAbi)
    {
        Rule storage r = rules[ruleId];
        return (r.contr, r.majority, r.funcAbi);
    }

    /**
     * @dev Get total number of ballots.
     * @return The total number of ballots.
     */
    function getTotalBallots() external view returns(uint256) {
        return ballots.length;
    }

    /**
     * @dev Get ballot details. Uses to show the list of available proposal for voting
     * @param ballotId The ballot index
     * @return closeVote
     * @return ruleId
     * @return args
     * @return status
     * @return creator
     * @return totalVotes
     * @return votesYea
     */
    function getBallot(uint256 ballotId)
        external view returns(
        uint256 closeVote,
        uint256 ruleId,
        bytes memory args,
        Status status,
        address creator,
        uint256[4] memory totalVotes,
        uint256[4] memory votesYea)
    {
        Ballot storage b = ballots[ballotId];
        return (b.closeVote, b.ruleId, b.args, b.status, b.creator,b.totalVotes,b.votesYea);
    }

    /**
     * @dev Get number of participants who vote for ballot.
     * @param ballotId The ballot index
     * @return number of participants who take pert in voting
     */
    function getParticipantsNumber(uint256 ballotId) external view returns(uint256) {
        return ballots[ballotId].participant.length;
    }

    /**
     * @dev Get number of participant who vote for ballot.
     * @param ballotId The ballot index
     * @param start The start position (index) to return data.
     * @param number The number of records (positions) to return.
     * @return participants The list of participant primary addresses
     * @return mainVotes The ist of voting power in main (JNTR) tokens
     * @return etnVotes The ist of voting power in ETN tokens
     * @return stockVotes The ist of voting power in Stock tokens
     * @return votes The list of votes (1 -Yea, 2 -Nay).
     */
    function getParticipants(uint256 ballotId, uint256 start, uint256 number) external view
        returns(address[] memory participants,
        uint256[] memory mainVotes,
        uint256[] memory etnVotes,
        uint256[] memory stockVotes,
        Vote[] memory votes)
    {
        Ballot storage b = ballots[ballotId];
        participants = new address[](number);
        mainVotes = new uint256[](number);
        etnVotes = new uint256[](number);
        stockVotes = new uint256[](number);
        votes = new Vote[](number);
        uint256 len = number;
        if (start + number > b.participant.length)
            len = b.participant.length - start;
        for(uint i = 0; i < len; i++) {
            participants[i] = b.participant[start + i];
            mainVotes[i] = b.power[participants[i]][0]; // voting power in community A (Main token)
            etnVotes[i] = b.power[participants[i]][1]; // voting power in community B (ETN token)
            stockVotes[i] = b.power[participants[i]][2]; // voting power in community C (STOCK token)
            votes[i] = b.votes[participants[i]];
        }
    }

    /**
     * @dev Create new proposal (ballot)
     * @param ruleId The rule id which parameter propose to change.
     * @param args The list of parameters.
     * @param isExpedited The proposal should be expedited if user have more then 10% of circulation supply.
     */
    function createBallot(uint256 ruleId, bytes memory args, bool isExpedited) external {
        require(ruleId < rules.length,"Wrong rule ID");
        Rule storage r = rules[ruleId];
        _getCirculation(r.majority);   //require update circulationSupply of Main token
        (address primary, uint256[4] memory power) = _getVotingPower(msg.sender, r.majority, false, true);
        uint256 highestPercentage;
        for (uint i = 0; i < 4; i++) {
            if (circulationSupply[i] > 0) {
                uint256 percentage = power[i] * 100 / circulationSupply[i]; // ownership percentage of token
                if (percentage > highestPercentage) highestPercentage = percentage;
            }
        }
        require(highestPercentage > 0, "Less then 1% of circulationSupply");
        uint256 ballotId = ballots.length;
        Ballot memory b;
        b.ruleId = ruleId;
        b.args = args;
        b.creator = msg.sender;
        b.votesYea = power;
        b.totalVotes = power;

        if(highestPercentage >= expeditedLevel && isExpedited && r.majority[0] < absoluteLevel) {
            // proposal can be expedited if user has 10% of Main token circulation supply
            // and requiring majority is less then 90%
            b.closeVote = 24 hours;
        }

        if (block.timestamp + 24 hours <= closeTime) {
            if(b.closeVote == 0)
                b.closeVote = closeTime;
            else {
                b.closeVote += block.timestamp; // Expedited vote
                emit ExpeditedBallot(ballotId, b.closeVote);
            }
        }
        else {
            b.status = Status.Pending;
        }
        ballots.push(b);
        emit AddBallot(msg.sender, ruleId, ballotId);
        // Add vote Yea
        ballots[ballotId].participant.push(primary); // add creator primary address as participant
        ballots[ballotId].votes[primary] = Vote.Yea;
        for (uint i = 0; i < 4; i++) {
            if (power[i] > 0) {
                ballots[ballotId].power[primary][i] = power[i];
            }
        }
        emit NewVote(msg.sender, primary, ballotId);

        if (highestPercentage >= 50) {
            // Check creator voting power for majority 50%+1 of total circulation supply
            if (_checkMajority(r.majority, power, power, false) == Vote.Yea) { // check Instant execution
                ballots[ballotId].status = Status.Approved;
                _executeBallot(ballotId);
            }
        }
    }

    /**
     * @dev Cancel proposal.
     * @param ballotId The ballot index
     */
    function cancelBallot(uint256 ballotId) external {
        require(ballotId < ballots.length,"Wrong ballot ID");
        Ballot storage b = ballots[ballotId];
        require(msg.sender == b.creator,"Only creator can cancel");
        b.closeVote = block.timestamp;
        b.status = Status.Canceled;
        if (unprocessedBallot == ballotId) unprocessedBallot++;
    }

    /**
     * @dev Vote for proposal.
     * @param ballotId The ballot index
     * @param v The user vote (1 - Yea, 2 - Nay)
     */
    function vote(uint256 ballotId, Vote v) external {
        require(ballotId < ballots.length,"Wrong ballot ID");
        Ballot storage b = ballots[ballotId];
        require(v != Vote.None, "Should vote Yea or Nay");
        require(b.status == Status.New, "Voting for disallowed");
        require(b.closeVote > block.timestamp, "Ballot expired");
        (address primary, uint256[4] memory power) = _getVotingPower(msg.sender, rules[b.ruleId].majority, false, true);
        if (b.votes[primary] == Vote.None) {
            // Add vote
            b.participant.push(primary); // add creator primary address as participant
            b.votes[primary] = v;
            for (uint i = 0; i < 4; i++) {
                if (power[i] > 0) {
                    b.power[primary][i] = power[i];  // store user's voting power
                    b.totalVotes[i] += power[i];
                    if (v == Vote.Yea)
                        b.votesYea[i] += power[i];
                }
            }
            // add CEO wallet as participant only for Absolute majority voting
            if (rules[b.ruleId].majority[0] >= absoluteLevel && walletsCEO.contains(msg.sender)) {
                b.ceoParticipate++;
            }
            emit NewVote(msg.sender, primary, ballotId);
        }
        else if (b.votes[primary] != v) {
            // Change vote
            b.votes[primary] = v;
            for (uint i = 0; i < 4; i++) {
                if (power[i] > 0) {
                    if (v == Vote.Yea)
                        b.votesYea[i] += power[i];
                    else
                        b.votesYea[i] -= b.power[primary][i];   // remove previous votes
                    b.totalVotes[i] = b.totalVotes[i] + power[i] - b.power[primary][i];
                    b.power[primary][i] = power[i];  // store user's voting power
                }
            }
            emit ChangeVote(msg.sender, primary, ballotId);
        }

        if (_checkMajority(rules[b.ruleId].majority, b.votesYea, b.totalVotes, false) != Vote.None) { // check Instant execution
            // Server-side may watch for PosableMajority event.
            // If it emitted the server-side may call verify function to apply changes without waiting voting close.
            emit PosableMajority(ballotId);
        }
    }

    /**
     * @dev Verify voting. Can be called many times if there are too many participants which cause Out of Gas error.
     * @param ballotId The ballot index
     * @param part The number of participant to verify. Uses to avoid Out of Gas.
     */
    function verify(uint256 ballotId, uint part) external {
        _verify(ballotId, part);
    }

    /**
     * @dev Verify next unverified voting. Can be called many times if there are too many participants which cause Out of Gas error.
     * @param part The number of participant to verify. Uses to avoid Out of Gas.
     */
    function verifyNext(uint part) external {
        uint len = ballots.length;
        for (uint i = unprocessedBallot; i < len; i++) {
            if (ballots[i].status == Status.New) {
                _verify(i, part);
                return; // exit after verification to avoid Out of Gas error
            }
            else if (ballots[i].status != Status.Pending && unprocessedBallot == i)
                unprocessedBallot++;
        }
    }

    /**
     * @dev Calculate Circulation Supply = Total supply - sum(excluded addresses balance)
     */
    function getCirculation() external {
        uint8[4] memory m;
        for (uint i = 0; i < 4; i++) {
            if (tokenContract[i] != IERC20Token(0))
                m[i] = 50;
        }
        _getCirculation(m);
    }

    /**
     * @dev Apply changes from ballot.
     * @param ballotId The ballot index
     */
    function _executeBallot(uint256 ballotId) internal {
        require(ballots[ballotId].status == Status.Approved,"Ballot is not Approved");
        Ballot storage b = ballots[ballotId];
        Rule storage r = rules[b.ruleId];
        bytes memory command;
        command = abi.encodePacked(bytes4(keccak256(bytes(r.funcAbi))), b.args);
        governanceProxy.trigger(r.contr, command);
        b.closeVote = block.timestamp;
        if (unprocessedBallot == ballotId) unprocessedBallot++;
        emit ApplyBallot(b.ruleId, ballotId);
    }

    /**
     * @dev Verify voting. Can be called many times if there are too many participants which cause Out of Gas error.
     * @param ballotId The ballot index
     * @param part The number of participant to verify. Uses to avoid Out of Gas.
     */
    function _verify(uint256 ballotId, uint part) internal {
        require(ballotId < ballots.length,"Wrong ballot ID");
        Ballot storage b = ballots[ballotId];
        Rule storage r = rules[b.ruleId];
        require(b.status == Status.New, "Can not be verified");
        uint256[4] memory totalVotes;
        uint256[4] memory totalYea;
        if (b.processedParticipants > 0) {  // continue verification
            totalVotes = b.totalVotes;
            totalYea = b.votesYea;
        }
        uint256 len = b.processedParticipants + part;
        if (len > b.participant.length || b.closeVote > block.timestamp) // if voting is not closed only etire number of participants should be count
            len = b.participant.length;
        bool acceptEscrowed = true;
        if (r.majority[0] >= absoluteLevel && b.ceoParticipate < requiredCEO)  // only for Absolute majority voting
            acceptEscrowed = false; // reject escrowed wallets if CED did not vote with required number of wallets
        for (uint i = b.processedParticipants; i < len; i++) {
            (address primary, uint256[4] memory power) = _getVotingPower(b.participant[i], r.majority, true, acceptEscrowed);
            for (uint j = 0; j < 4; j++) {
                if (power[j] > 0) {
                    totalVotes[j] += power[j];
                    if (b.votes[primary] == Vote.Yea){
                        totalYea[j] += power[j];
                    }
                }
                b.power[primary][j] = power[j]; // store user's voting power
            }
        }
        b.processedParticipants = len;
        b.votesYea = totalYea;
        b.totalVotes = totalVotes;
        Vote result;
        if (len == b.participant.length) {
            // Check Absolute majority at first
            _getCirculation(r.majority);
            if (b.closeVote < block.timestamp) // if vote closed
            {
                result = _checkMajority(r.majority, totalYea, totalVotes, true);
                if (result == Vote.None) result = Vote.Nay; // if no required majority then reject proposal
            }
            else
                result = _checkMajority(r.majority, totalYea, totalVotes, false);  // Check majority for instant execution
            if (result == Vote.Yea) {
                b.status = Status.Approved;
                _executeBallot(ballotId);
            }
            else if (result == Vote.Nay) {
                b.status = Status.Rejected;
                b.closeVote = block.timestamp;
                if (unprocessedBallot == ballotId) unprocessedBallot++;
            }
            else
                b.processedParticipants = 0; //continue voting and reset counter to be able recount votes
        }
    }

    /**
     * @dev Calculate Circulation Supply = Total supply - sum(excluded addresses balance).
     * @param tokensApply if element of array = 0 then exclude that token (index: 0 = MainToken, 1 = ETN, 2 = STOCK)
     * @param votesYea The total voting power said Yea.
     * @param totalVotes The total voting power of all participants.
     * @param isClosed the voting is closed
     * @return result the majority Yea (1), Nay (2) in case absolute majority, or None (0) if no majority.
    */
    function _checkMajority(
        uint8[4] memory tokensApply,
        uint256[4] memory votesYea,
        uint256[4] memory totalVotes,
        bool isClosed)
        internal view returns(Vote result)
    {
        uint256 majorityYea;
        uint256 majorityNay;
        uint256 requireMajority;
        for (uint i = 0; i < 4; i++) {
            if (tokensApply[i] != 0) {
                requireMajority++;
                // check majority of circulation supply at first
                if (votesYea[i] * 2 > circulationSupply[i])
                    majorityYea++;   // the voting power is more then 50% of circulation supply
                else if ((totalVotes[i]-votesYea[i]) * 2 > circulationSupply[i])
                    majorityNay++;   // the voting power is more then 50% of circulation supply
                else if (isClosed && votesYea[i] > totalVotes[i] * tokensApply[i] / 100)
                    majorityYea++;   // the voting power is more then require of all participants total votes power
            }
        }
        if (majorityYea == requireMajority) result = Vote.Yea;
        else if (majorityNay == requireMajority) result = Vote.Nay;
    }

    /**
     * @dev Calculate Circulation Supply = Total supply - sum(excluded addresses balance)
     * @param tokensApply if element of array = 0 then exclude that token (index: 0 = MainToken, 1 = ETN, 2 = STOCK)
     */
    function _getCirculation(uint8[4] memory tokensApply) internal {
        uint256[4] memory total;
        for (uint i = 0; i < 4; i++) {
            if (tokensApply[i] != 0 && circulationSupplyUpdated[i] != block.timestamp) {
                uint len = excluded[i].length;
                for (uint j = 0; j < len; j++) {
                    total[i] += tokenContract[i].balanceOf(excluded[i][j]);
                    if (escrowContract[i] != IERC20Token(0) && isInEscrow[i][excluded[i][j]]) {
                        total[i] += escrowContract[i].balanceOf(excluded[i][j]);
                    }
                }
                uint256 t = IERC20Token(tokenContract[i]).totalSupply();
                require(t >= total[i], "Total Supply less then accounts balance");
                circulationSupply[i] = t - total[i];
                circulationSupplyUpdated[i] = block.timestamp;  // timestamp when circulationSupply updates
            }
        }
    }

    /**
     * @dev Calculate Voting Power of voter in provided communities (tokens)
     * @param voter The wallet address of voter.
     * @param tokensApply if element of array = 0 then exclude that token (index: 0 = MainToken, 1 = ETN, 2 = STOCK)
     * @param isPrimary is true when voter address is primary address. Uses in verify function.
     * @return primary - The primary address the wallet belong.
     * @return votingPower - the voting power according communities.
     */
    function _getVotingPower(address voter, uint8[4] memory tokensApply, bool isPrimary, bool acceptEscrowed) internal view
        returns(address primary, uint256[4] memory votingPower)
    {
        if (isPrimary)
            primary = voter;
        else
            primary = whitelist.address_belongs(voter);
        require (!blockedWallets[primary], "Wallet is blocked for voting");
        address[] memory userWallets;
        if (primary != address(0)) {
            userWallets = whitelist.getUserWallets(primary);
        }
        else {
            primary = voter;
            userWallets = new address[](0);
        }
        bool hasPower = false;
    
        for (uint i = 0; i < 4; i++) {
            if (tokensApply[i] != 0) {
                votingPower[i] += tokenContract[i].balanceOf(primary);
                if (acceptEscrowed && escrowContract[i] != IERC20Token(0) && isInEscrow[i][primary]) {
                    votingPower[i] += escrowContract[i].balanceOf(primary);
                }
                for(uint j = 0; j < userWallets.length; j++) {
                    votingPower[i] += tokenContract[i].balanceOf(userWallets[j]);
                    if (acceptEscrowed && escrowContract[i] != IERC20Token(0) && isInEscrow[i][userWallets[j]]) {
                        votingPower[i] += escrowContract[i].balanceOf(userWallets[j]);
                    }
                }
                if (votingPower[i] > 0) hasPower = true;
            }
        }
        require(isPrimary || hasPower, "No voting power");
    }

    /**
     * @dev Calculate number of days from 1/1/1970 to selected date.
     * @param year The year number
     * @param month The month number
     * @param day The day number
     * @return _days number of day.
     */
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - 2440588;

        _days = uint(__days);
    }

    /**
     * @dev Calculate timestamp (UNIX time) of selected date and time.
     * @param year The year number
     * @param month The month number
     * @param day The day number
     * @param hour number of hours
     * @param minute number of minutes
     * @param second number of seconds
     * @return timestamp UNIX time
     */
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * 86400 + hour * 3600 + minute * 60 + second;
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + 2440588;
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

    /**
     * @dev Calculate date from timestamp (UNIX time) .
     * @param timestamp UNIX time
     * @return year The year number
     * @return month The month number
     * @return day The day number
     */
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / 86400);
    }
}
