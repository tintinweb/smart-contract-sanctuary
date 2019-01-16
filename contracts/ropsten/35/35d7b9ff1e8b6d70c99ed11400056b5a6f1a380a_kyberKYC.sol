pragma solidity ^0.4.24;
contract kyberKYC {
    address public admin;

    struct User {
        //Read/write candidate
        address userAddr;
        //Ghi cang nhieu tren BC thi cang tot tien
        string userName;
        string userEmail;
    }
    // 1 list danh sach user 
    mapping (address => User) public companyUserMap;
    //tac dung cua event: nhu 1 log: giup cho viec debug dang di den dau 
    //log2: muon thong ke thong so thi check event, check lai lich su.
    
    event AddUser(address indexed _userAddr, string _userName, string userEmail);
    event RemoveUser(address indexed _userAddr);
    
    //constructor
    //KHoi tao contract: khi moi nguoi deploy thi moi nguoi la admin luon ( nguoi gui chinh la admin)
    //can co co che chuyen admin cho nguoi khac
    constructor () public {
        admin =  msg.sender;
    }
    //Ham nay admin se lam, de add user.
    //sau khi da deploy thi ai cung goi duoc ham addUser
    //Nguoi lam function admin, co nghia la phai la admin moi dung duoc ham nay.
    function addUser(address _userAddr, string _userName, string _userEmail) public {
        
        require(
            msg.sender == address(admin),
            "Only admin can call this."
            );
            companyUserMap[_userAddr] = User(_userAddr, _userName,_userEmail);
            //emit AddUser(_userAddr, _userName, _userEmail);
    }
    //0x0 kieu defaul cua kieu address la 0x0
    function removeUser(address _userAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
            );
            companyUserMap[_userAddr] = User(0x0,"","");
            //emit RemoveUser(_userAddr)
    }
    
    //
    function isUserKyc(address _userAddr) constant public returns (bool){
        return companyUserMap[_userAddr].userAddr == _userAddr;
    }
    //
    function transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
            );
            admin = _adminAddr;
    }

    /*address chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;

    /// Create a new ballot with $(_numProposals) different proposals.
    function Ballot(uint8 _numProposals) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        proposals.length = _numProposals;
    }

    /// Give $(toVoter) the right to vote on this ballot.
    /// May only be called by $(chairperson).
    function giveRightToVote(address toVoter) public {
        if (msg.sender != chairperson || voters[toVoter].voted) return;
        voters[toVoter].weight = 1;
    }

    /// Delegate your vote to the voter $(to).
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender]; // assigns reference
        if (sender.voted) return;
        while (voters[to].delegate != address(0) && voters[to].delegate != msg.sender)
            to = voters[to].delegate;
        if (to == msg.sender) return;
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegateTo = voters[to];
        if (delegateTo.voted)
            proposals[delegateTo.vote].voteCount += sender.weight;
        else
            delegateTo.weight += sender.weight;
    }

    /// Give a single vote to proposal $(toProposal).
    function vote(uint8 toProposal) public {
        Voter storage sender = voters[msg.sender];
        if (sender.voted || toProposal >= proposals.length) return;
        sender.voted = true;
        sender.vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
    }

    function winningProposal() public constant returns (uint8 _winningProposal) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++)
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
            }
    }*/
}