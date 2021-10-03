// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Exercies {
    uint256 public memCount;

    mapping(address => bool) public isMember; // list member
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        internal isvoted;

    address public owner;

    event addMember(address indexed account, uint256 numVotes);
    event removeMember(address indexed account, uint256 numVotes);

    event transactiongroupDeposit(
        address indexed account,
        uint256 amount,
        uint256 voteCount
    );
    event transactionVotingToken(
        address indexed Votee,
        ERC20 tokenAddr,
        uint256 _countVote,
        uint256 typeTransaction
    );

    event transactionETH(
        address indexed _member,
        uint256 _ethVal,
        string typeTransaction
    );
    event transactionETH__multi(
        address indexed _member,
        address _recipient,
        uint256 _ethVal,
        string typeTransaction
    );
    event transactionTOKEN(
        address indexed _member,
        ERC20 indexed _token,
        uint256 _tokenVal,
        string typeTransaction
    );
    event transactionTOKEN_multi(
        address indexed _member,
        address _recipient,
        ERC20 indexed _token,
        uint256 _tokenVal,
        string typeTransaction
    );
    event transactionVoting(
        address indexed epositVotee,
        uint256 _countVote,
        string typeTransaction
    );

    fallback() external payable {}

    receive() external payable {}

    struct member {
        uint256 id;
        address candidateAddr;
    }

    //Candidate
    struct candidate {
        uint256 id;
        address candidateAddr;
        uint256 typeVote; //1 = add, 2 = remove
        uint256 numVotes;
    }

    struct pendingETH {
        uint256 id;
        address candidateAddr;
        uint256 typeVote; // 3 = depositETH, 4 = withdrawETH
        uint256 amount;
        address recipient;
        uint256 numVotes;
    }

    //Candidate
    struct pendingToken {
        uint256 id;
        address candidateAddr;
        uint256 typeVote; //5 = depositToken, 6 = withdrawtoken
        uint256 amount;
        ERC20 tokenAddr;
        address recipient;
        uint256 numVotes;
    }

    //voting Session
    struct votingSession {
        uint256 id; // starts from 1
        uint256 votename;
        uint256 votee;
    }

    mapping(uint256 => mapping(uint256 => candidate)) public candidates;
    mapping(uint256 => member) public members;
    mapping(uint256 => mapping(uint256 => pendingETH)) public pendingeths;
    mapping(uint256 => mapping(uint256 => pendingToken)) public pendingtokens;
    mapping(uint256 => votingSession) public votingArray;

    // Number of Candidates in pending status
    uint256 public pendingAddCount = 0;
    uint256 public pendingRemoveCount = 0;
    uint256 public pendingDepositETHCount = 0;
    uint256 public pendingWithdrawETHCount = 0;
    uint256 public pendingDepositTokenCount = 0;
    uint256 public pendingWithdrawTokenCount = 0;

    //number of voting sesion
    uint256 public numVotingSession = 0;

    //Number of final result votes
    uint256 private finalResultAdd = 0;
    uint256 private finalResultRemove = 0;
    uint256 private finalResultDepositETH = 0;
    uint256 private finalResultWithdrawETH = 0;
    uint256 private finalResultDepositToken = 0;
    uint256 private finalResultWithdrawToken = 0;

    //variable used to store balance of contract, msg.sender, recipient when waiting vote deposit ETH
    uint256 public totalETH;
    uint256 public totalETHSender;

    //state of voting session
    enum State {
        Created,
        Voting,
        finishVoting
    }
    State private state;

    constructor() {
        owner = msg.sender;
        isMember[msg.sender] = true;
        memCount = 1;
        members[memCount] = member(memCount, msg.sender);
        numVotingSession = 0;
        totalETH = address(this).balance; //store balance of contract
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not member");
        _;
    }

    //Create waiting pending vote
    function pendingAdd(address candidateAddr) internal {
        pendingAddCount++;
        candidates[pendingAddCount][1] = candidate(
            pendingAddCount,
            candidateAddr,
            1,
            0
        );
    }

    function pendingRemove(address candidateAddr) internal {
        pendingRemoveCount++;
        candidates[pendingRemoveCount][2] = candidate(
            pendingRemoveCount,
            candidateAddr,
            2,
            0
        );
    }

    function pendingDepositETH(address candidateAddr, uint256 amount) internal {
        pendingDepositETHCount++;
        pendingeths[pendingDepositETHCount][3] = pendingETH(
            pendingDepositETHCount,
            candidateAddr,
            3,
            amount,
            address(this),
            0
        );
    }

    function pendingWithdrawETH(
        address candidateAddr,
        address recipient,
        uint256 amount
    ) internal {
        pendingWithdrawETHCount++;
        pendingeths[pendingWithdrawETHCount][4] = pendingETH(
            pendingWithdrawETHCount,
            candidateAddr,
            4,
            amount,
            recipient,
            0
        );
    }

    function pendingDepositToken(
        address candidateAddr,
        uint256 amount,
        ERC20 tokenAddr
    ) internal {
        pendingDepositTokenCount++;
        pendingtokens[pendingDepositTokenCount][5] = pendingToken(
            pendingDepositTokenCount,
            candidateAddr,
            5,
            amount,
            tokenAddr,
            address(this),
            0
        );
    }

    function pendingWithdrawToken(
        address candidateAddr,
        address recipient,
        uint256 amount,
        ERC20 tokenAddr
    ) internal {
        pendingWithdrawTokenCount++;
        pendingtokens[pendingWithdrawTokenCount][6] = pendingToken(
            pendingWithdrawTokenCount,
            candidateAddr,
            6,
            amount,
            tokenAddr,
            recipient,
            0
        );
    }

    //initiate voting session
    function startVote() internal inState(State.Created) {
        state = State.Voting;
    }

    //call candidateID in waiting pending vote
    function doVote(uint256 candidateID, uint256 votetype)
        public
        inState(State.Voting)
    {
        // require that they haven't voted before
        require(isMember[msg.sender], "not member");

        require(
            votetype == 1 ||
                votetype == 2 ||
                votetype == 3 ||
                votetype == 4 ||
                votetype == 5 ||
                votetype == 6,
            " vote type not exist "
        );

        require(!isvoted[msg.sender][candidateID][votetype], "already voted");

        // require(state != State.finishVoting, "voting session already finished");

        if (votetype == 1) {
            require(
                candidateID <= pendingAddCount,
                " ID not exist in pendingAdd "
            );
            // record that voter has voted
            isvoted[msg.sender][candidateID][1] = true; // msg.sender is the caller address

            // update candidate vote Count
            ++candidates[candidateID][1].numVotes;

            numVotingSession++;

            votingArray[numVotingSession] = votingSession(
                numVotingSession,
                votetype,
                candidateID
            );
        }

        if (votetype == 2) {
            require(
                candidateID <= pendingRemoveCount,
                " ID not exist in pendingRemove "
            );
            // record that voter has voted
            isvoted[msg.sender][candidateID][votetype] = true; // msg.sender is the caller address

            // update candidate vote Count
            ++candidates[candidateID][2].numVotes;

            numVotingSession++;

            votingArray[numVotingSession] = votingSession(
                numVotingSession,
                votetype,
                candidateID
            );
        }

        if (votetype == 3) {
            require(
                candidateID <= pendingDepositETHCount,
                "ID not exist in pendingDeposit"
            );
            // record that voter has voted
            isvoted[msg.sender][candidateID][votetype] = true; // msg.sender is the caller address

            // update candidate vote Count
            ++pendingeths[candidateID][3].numVotes;

            numVotingSession++;

            votingArray[numVotingSession] = votingSession(
                numVotingSession,
                votetype,
                candidateID
            );
        }

        if (votetype == 4) {
            require(
                candidateID <= pendingWithdrawETHCount,
                "ID not exist in pendingWithdraw"
            );
            // record that voter has voted
            isvoted[msg.sender][candidateID][4] = true; // msg.sender is the caller address

            // update candidate vote Count
            ++pendingeths[candidateID][4].numVotes;

            numVotingSession++;

            votingArray[numVotingSession] = votingSession(
                numVotingSession,
                votetype,
                candidateID
            );
        }

        if (votetype == 5) {
            require(
                candidateID <= pendingDepositTokenCount,
                "ID not exist in pendingWithdraw"
            );
            // record that voter has voted
            isvoted[msg.sender][candidateID][5] = true; // msg.sender is the caller address

            // update candidate vote Count
            ++pendingtokens[candidateID][5].numVotes;

            numVotingSession++;

            votingArray[numVotingSession] = votingSession(
                numVotingSession,
                votetype,
                candidateID
            );
        }

        if (votetype == 6) {
            require(
                candidateID <= pendingWithdrawTokenCount,
                "ID not exist in pendingWithdraw"
            );
            // record that voter has voted
            isvoted[msg.sender][candidateID][6] = true; // msg.sender is the caller address

            // update candidate vote Count
            ++pendingtokens[candidateID][6].numVotes;

            numVotingSession++;

            votingArray[numVotingSession] = votingSession(
                numVotingSession,
                votetype,
                candidateID
            );
        }
    }

    //end and count votes
    function finalize(uint256 candidateID, uint256 votetype)
        public
        inState(State.Voting)
        returns (bool)
    {
        require(
            votetype == 1 || votetype == 2 || votetype == 3 || votetype == 4,
            " only return final Result for vote add or vote remove or vote deposit or vote withdraw ETH function "
        );

        // require(state != State.finishVoting, "voting session already finished");

        if (votetype == 1) {
            require(
                candidateID <= pendingAddCount,
                " ID not exist in pendingAdd "
            );

            finalResultAdd = candidates[candidateID][1].numVotes;

            //enough votes add
            if (finalResultAdd * 100 >= 50 * memCount) {
                state = State.finishVoting;

                memCount++;

                isMember[candidates[candidateID][1].candidateAddr] = true;
                members[memCount] = member(
                    memCount,
                    candidates[candidateID][1].candidateAddr
                );
                emit addMember(
                    candidates[candidateID][votetype].candidateAddr,
                    finalResultAdd
                );
                //voteCount[votee]=0;
            } else {
                state = State.Voting;
            }
        }

        if (votetype == 2) {
            require(
                candidateID <= pendingRemoveCount,
                " ID not exist in pendingRemove "
            );

            finalResultRemove = candidates[candidateID][2].numVotes;

            //enough votes remove
            if (finalResultRemove * 100 >= 50 * memCount) {
                state = State.finishVoting;
                members[memCount] = member(
                    memCount,
                    candidates[candidateID][1].candidateAddr
                );
                memCount--;
                isMember[
                    candidates[candidateID][votetype].candidateAddr
                ] = false;
                emit removeMember(
                    candidates[candidateID][votetype].candidateAddr,
                    finalResultRemove
                );
            } else {
                state = State.Voting;
            }
        }

        if (votetype == 3) {
            require(
                candidateID <= pendingDepositETHCount,
                "ID not exist in pendingDeposit"
            );

            finalResultDepositETH = pendingeths[candidateID][3].numVotes;

            //enough vote deposit
            if (finalResultDepositETH == memCount) {
                state = State.finishVoting;

                uint256 amountDeposit = pendingeths[candidateID][3].amount;

                totalETH = totalETH + amountDeposit;

                totalETHSender = totalETHSender - amountDeposit;
            } else {
                state = State.Voting;
            }
        }

        if (votetype == 4) {
            require(
                candidateID <= pendingWithdrawETHCount,
                "ID not exist in pendingWithdraw"
            );

            finalResultWithdrawETH = pendingeths[candidateID][4].numVotes;
            //enoungh vote withdraw
            if (finalResultWithdrawETH * 100 > 50 * memCount) {
                state = State.finishVoting;

                uint256 amountWithdraw = pendingeths[candidateID][4].amount;

                // totalETH = totalETH - amountWithdraw;
                // totalETHRecipient =  totalETHRecipient + amountWithdraw;
                payable(pendingeths[candidateID][4].recipient).transfer(
                    amountWithdraw
                );
            } else {
                state = State.Voting;
            }
        }

        return true;
    }

    function finalizeToken(
        uint256 candidateID,
        uint256 votetype,
        ERC20 tokenAddr
    ) public inState(State.Voting) returns (bool) {
        require(
            votetype == 5 || votetype == 6,
            " only return final Result for vote deposit token or withdraw token function "
        );

        // require(state != State.finishVoting, "voting session already finished");

        if (votetype == 5) {
            require(
                candidateID <= pendingDepositTokenCount,
                "ID not exist in pending deposit token"
            );

            finalResultDepositToken = pendingtokens[candidateID][5].numVotes;
            //enoungh vote deposit token
            if (finalResultDepositToken == memCount) {
                state = State.finishVoting;

                uint256 amountDepositToken = pendingtokens[candidateID][5]
                    .amount;

                ERC20(tokenAddr).transferFrom(
                    pendingtokens[candidateID][5].candidateAddr,
                    address(this),
                    amountDepositToken
                );
            } else {
                state = State.Voting;
            }
        }

        if (votetype == 6) {
            require(
                candidateID <= pendingWithdrawTokenCount,
                "ID not exist in pendingWithdraw"
            );

            finalResultWithdrawToken = pendingtokens[candidateID][6].numVotes;

            //enoungh vote withdraw token
            if (finalResultWithdrawToken * 100 > 50 * memCount) {
                state = State.finishVoting;

                uint256 amountWithdrawToken = pendingtokens[candidateID][6]
                    .amount;

                ERC20(tokenAddr).transfer(
                    pendingtokens[candidateID][6].recipient,
                    amountWithdrawToken
                );
            } else {
                state = State.Voting;
            }
        }

        return true;
    }

    //initiate vote Add session
    function addMem(address votee) public returns (bool) {
        state = State.Created;
        //Kiểm tra xem người vote được vote hay ko
        require(isMember[msg.sender], "not member");
        require(!isMember[votee], "votee is already a member ");
        //require(votingSessionID > numVotingSession, "votingSessionID is already exist ");
        pendingAdd(votee);
        startVote();
        return true;
    }

    // function listMem(uint memID ) view public {

    //     require( isMember[msg.sender], "not member");
    //     require(memID <= memCount, "ID not member ");
    //     members[memID];

    // }

    //initiate vote remove session
    function removeMem(address votee) public returns (bool) {
        state = State.Created;
        //Kiểm tra xem người vote được vote hay ko
        require(isMember[msg.sender], "not member");
        require(isMember[votee], "votee is not a member yet");
        pendingRemove(votee);
        startVote();
        return true;
    }

    //initiate vote deposit session
    function groupDepositETH(uint256 amountDeposit) public {
        state = State.Created;
        totalETHSender = msg.sender.balance;
        amountDeposit = amountDeposit * (10**18);
        require(isMember[msg.sender], "not member");
        require(amountDeposit <= msg.sender.balance, "not enough balance");
        pendingDepositETH(msg.sender, amountDeposit);
        startVote();
    }

    //initiate vote withdraw session
    function groupWithdrawETH(address recipient, uint256 amountWithdraw)
        public
    {
        require(isMember[msg.sender], "not member");
        amountWithdraw = amountWithdraw * (10**18);
        require(address(this).balance >= amountWithdraw, "not enough balance");
        state = State.Created;
        // totalETHRecipient = recipient.balance ;
        pendingWithdrawETH(msg.sender, recipient, amountWithdraw);
        startVote();
    }

    function groupDepositTOKEN(ERC20 tokenAddress, uint256 amounttoken) public {
        state = State.Created;
        require(isMember[msg.sender], "not member");
        require(
            amounttoken <= ERC20(tokenAddress).balanceOf(msg.sender),
            "not enough balance"
        );
        ERC20(tokenAddress).approve(msg.sender, amounttoken);
        pendingDepositToken(msg.sender, amounttoken, tokenAddress);
        startVote();
    }

    // //initiate vote withdraw session
    function groupWithdrawTOKEN(
        address recipient,
        uint256 amountWithdraw,
        ERC20 tokenAddress
    ) public {
        require(isMember[msg.sender], "not member");
        require(isMember[recipient], "not member");
        require(
            ERC20(tokenAddress).balanceOf(address(this)) >= amountWithdraw,
            "not enough balance"
        );
        state = State.Created;
        // totalETHRecipient = recipient.balance ;
        pendingWithdrawToken(
            msg.sender,
            recipient,
            amountWithdraw,
            tokenAddress
        );
        startVote();
    }

    //get balance ETH or any token

    function balanceOfETH() public view returns (uint256) {
        require(isMember[msg.sender], "not member");
        return address(this).balance;
    }

    function balanceOfTOKEN(address _tokenAddress, address _addressToQuery)
        public
        view
        returns (uint256)
    {
        require(isMember[msg.sender], "not member");
        //Lay balance của member đó tại địa chỉ token đó
        return ERC20(_tokenAddress).balanceOf(_addressToQuery);
    }

    // deposit ETH or any token

    function DepositETH() public payable {
        require(isMember[msg.sender], "not member");
        uint256 rate = (address(this).balance * 30) / 100;
        if (address(this).balance != msg.value) {
            require(
                msg.value <= rate,
                "only deposit up to 30% total ETH amount that the smart contract hold"
            );
            emit transactionETH(msg.sender, msg.value, "deposit");
        } else {
            emit transactionETH(msg.sender, msg.value, "deposit");
        }
    }

    function DepositTOKEN(ERC20 _tokenAddress, uint256 _amount) public {
        require(isMember[msg.sender], "not member");
        require(
            _amount <= ERC20(_tokenAddress).balanceOf(msg.sender),
            "not enough balance"
        );

        uint256 rate = (ERC20(_tokenAddress).balanceOf(address(this)) * 30) /
            100;

        if (ERC20(_tokenAddress).balanceOf(address(this)) != 0) {
            require(
                _amount <= rate,
                "only deposit up to 30% total Token amount that the smart contract hold"
            );

            // TestToken(_tokenAddress).transfer(address(this), _amount);
            ERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            emit transactionTOKEN(
                msg.sender,
                _tokenAddress,
                _amount,
                "deposit"
            );
        } else {
            ERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            emit transactionTOKEN(
                msg.sender,
                _tokenAddress,
                _amount,
                "deposit"
            );
        }
    }

    // withdraw ETH or any token from contract to sender, or from contract to other account

    function withdrawETH(uint256 _amount) public {
        require(isMember[msg.sender], "not member");
        require(address(this).balance >= _amount, "not enough balance");
        payable(msg.sender).transfer(_amount);
    }

    function withdrawTOKEN(ERC20 _token, uint256 _amount)
        public
        returns (bool)
    {
        require(isMember[msg.sender], "not member");
        require(
            ERC20(_token).balanceOf(address(this)) >= _amount,
            "not enough token"
        );
        ERC20(_token).transfer(msg.sender, _amount);
        emit transactionTOKEN(msg.sender, _token, _amount, "withdraw");
        return true;
    }

    function withdrawETH_multi(address _recipient, uint256 _amount)
        public
        payable
    {
        require(isMember[msg.sender], "not member");
        require(isMember[_recipient], "not member");
        require(address(this).balance >= _amount, "not enough balance");
        payable(_recipient).transfer(_amount);
        emit transactionETH__multi(msg.sender, _recipient, _amount, "withdraw");
    }

    function withdrawTOKEN_multi(
        ERC20 _token,
        address _recipient,
        uint256 _amount
    ) public {
        require(isMember[msg.sender], "not member");
        require(isMember[_recipient], "not member");
        require(
            ERC20(_token).balanceOf(address(this)) >= _amount,
            "not enough balance"
        );
        emit transactionTOKEN_multi(
            msg.sender,
            _recipient,
            _token,
            _amount,
            "withdraw"
        );
        ERC20(_token).transfer(_recipient, _amount);
    }

    // function listMem() public {
    //     for(uint i = 0; i <= memCount; i++)
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract ERC20 is IERC20, MinterRole {
    
    using SafeMath for uint256;
    
    string private _name;
    string private _symbol;
    uint private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    constructor () {
        _name = "ERC20";
        _symbol = "ETK";
        _decimals = 18;
        _totalSupply = 20000 * (10 ** _decimals);
        _balances[msg.sender] =  _totalSupply;
    }

    function name()  external  view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint) {
        return _decimals;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) override external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value)override external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) 
    {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

    function mint(address account, uint256 amount) external onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

     function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _burnFrom(account, amount);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}