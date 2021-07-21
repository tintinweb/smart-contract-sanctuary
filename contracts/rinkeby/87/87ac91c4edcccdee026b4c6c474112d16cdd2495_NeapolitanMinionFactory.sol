/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// Based on https://github.com/HausDAO/MinionSummoner/blob/main/MinionFactory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

// import "hardhat/console.sol";

interface IERC20 { // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC1271 {
    function isValidSignature(bytes32 _messageHash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC1155Receiver {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

interface IMOLOCH { // brief interface for moloch dao v2


    function depositToken() external view returns (address);
    
    function tokenWhitelist(address token) external view returns (bool);

    function totalShares() external view returns (uint256);
    
    function getProposalFlags(uint256 proposalId) external view returns (bool[6] memory);

    function getUserTokenBalance(address user, address token) external view returns (uint256);
    
    function members(address user) external view returns (address, uint256, uint256, bool, uint256, uint256);
    
    function memberAddressByDelegateKey(address user) external view returns (address);

    function userTokenBalances(address user, address token) external view returns (uint256);
    
    function cancelProposal(uint256 proposalId) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);
    
    function withdrawBalance(address token, uint256 amount) external;

    struct Proposal {
        address applicant; // the applicant who wishes to become a member - this key will be used for withdrawals (doubles as guild kick target for gkick proposals)
        address proposer; // the account that submitted the proposal (can be non-member)
        address sponsor; // the member that sponsored the proposal (moving it into the queue)
        uint256 sharesRequested; // the # of shares the applicant is requesting
        uint256 lootRequested; // the amount of loot the applicant is requesting
        uint256 tributeOffered; // amount of tokens offered as tribute
        address tributeToken; // tribute token contract reference
        uint256 paymentRequested; // amount of tokens requested as payment
        address paymentToken; // payment token contract reference
        uint256 startingPeriod; // the period in which voting can start for this proposal
        uint256 yesVotes; // the total number of YES votes for this proposal
        uint256 noVotes; // the total number of NO votes for this proposal
        bool[6] flags; // [sponsored, processed, didPass, cancelled, whitelist, guildkick]
        string details; // proposal details - could be IPFS hash, plaintext, or JSON
        uint256 maxTotalSharesAndLootAtYesVote; // the maximum # of total shares encountered at a yes vote on this proposal
    }
    function proposals(uint256 proposalId) external returns (address, address, address, uint256, uint256, uint256, address, uint256, address, uint256, uint256, uint256);
}

contract DaoConditionalHelper {

    function isDaoMember(address user, address dao) public view {
        // member only check should check if member or delegate
        IMOLOCH moloch = IMOLOCH(dao);
        address memberAddress = moloch.memberAddressByDelegateKey(user);
        (, uint shares,,,,) = moloch.members(memberAddress);
        require(shares > 0, "Is Not Dao Member");
    }

    function isNotDaoMember(address user, address dao) public view {
        // member only check should check if member or delegate
        IMOLOCH moloch = IMOLOCH(dao);
        address memberAddress = moloch.memberAddressByDelegateKey(user);
        (, uint shares,,,,) = moloch.members(memberAddress);
        require(shares == 0, "Is Not Dao Member");
    }

    function isAfter(uint256 timestamp) public view {
        require(timestamp < block.timestamp, "timestamp not meet");
    }

}
contract NeapolitanMinion is IERC721Receiver, IERC1155Receiver, IERC1271 {
    IMOLOCH public moloch;
    address public molochDepositToken;
    address public module;
    uint256 public minQuorum;
    bool private initialized; // internally tracks deployment under eip-1167 proxy pattern
    mapping(uint256 => Action) public actions; // proposalId => Action

    // events consts

    string private constant ERROR_INIT = "Minion::initialized";
    string private constant ERROR_LENGTH_MISMATCH = "Minion::length mismatch";
    string private constant ERROR_REQS_NOT_MET = "Minion::proposal execution requirements not met";
    string private constant ERROR_NOT_VALID = "Minion::not a valid operation";
    string private constant ERROR_EXECUTED = "Minion::action already executed";
    string private constant ERROR_FUNDS = "Minion::insufficient native token";
    string private constant ERROR_CALL_FAIL = "Minion::call failure";
    string private constant ERROR_NOT_WL = "Minion::not a whitelisted token";
    string private constant ERROR_TX_FAIL = "Minion::token transfer failed";
    string private constant ERROR_NOT_PROPOSER = "Minion::not proposer";
    string private constant ERROR_THIS_ONLY = "Minion::can only be called by this";
    string private constant ERROR_MEMBER_ONLY = "Minion::not member";
    string private constant ERROR_NOT_SPONSORED = "Minion::proposal not sponsored";
    string private constant ERROR_NOT_PASSED = "Minion::proposal has not passed";

    struct Action {
        bytes32 id;
        address proposer;
        bool executed;
        address token;
        uint256 amount;
    }

    struct DAOSignature {
        bytes32 signatureHash;
        bytes4 magicValue;
        uint256 proposalId;
        address proposer;
    }

    mapping (bytes32 => DAOSignature) public signatures; // msgHash => Signature
    // todo lookup signature hash by
    mapping (uint256 => bytes32) msgHashes;

    event ProposeAction(bytes32 indexed id, uint256 indexed proposalId, uint256 index, address targets, uint256 values, bytes datas);
    event ExecuteAction(bytes32 indexed id, uint256 indexed proposalId, uint256 index, address targets, uint256 values, bytes datas, address executor);
    
    event DoWithdraw(address token, uint256 amount);
    event CrossWithdraw(address target, address token, uint256 amount);
    event PulledFunds(address moloch, uint256 amount);
    event ActionCanceled(uint256 proposalId);

    event ProposeSignature(uint256 proposalId, bytes32 msgHash, address proposer);
    event SignatureCanceled(uint256 proposalId, bytes32 msgHash);
    event ExecuteSignature(uint256 proposalId, address executor);

    event ChangeOwner(address owner);
    event SetModule(address module);
    
    modifier memberOnly() {
        require(isMember(msg.sender), ERROR_MEMBER_ONLY);
        _;
    }

    modifier thisOnly() {
        require(msg.sender == address(this), ERROR_THIS_ONLY);
        _;
    }

    function init(address _moloch, uint256 _minQuorum) external {
        require(!initialized, ERROR_INIT); 
        moloch = IMOLOCH(_moloch);
        minQuorum = _minQuorum;
        molochDepositToken = moloch.depositToken();
        initialized = true; 
    }

    function onERC721Received (address, address, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure override returns(bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure override returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
    
    //  -- Withdraw Functions --

    function doWithdraw(address token, uint256 amount) public memberOnly {
        moloch.withdrawBalance(token, amount); // withdraw funds from parent moloch
        emit DoWithdraw(token, amount);
    }
    
    function crossWithdraw(address target, address token, uint256 amount, bool transfer) external memberOnly {
        // @Dev - Target needs to have a withdrawBalance functions
        IMOLOCH(target).withdrawBalance(token, amount); 
        
        // Transfers token into DAO. 
        if(transfer) {
            bool whitelisted = moloch.tokenWhitelist(token);
            require(whitelisted, ERROR_NOT_WL);
            require(IERC20(token).transfer(address(moloch), amount), ERROR_TX_FAIL);
        }
        
        emit CrossWithdraw(target, token, amount);
    }

    //  -- Signature Interface --
    function isValidSignature(bytes32 permissionHash, bytes memory signature)
        public
        view
        override
        returns (bytes4)
    {
        DAOSignature memory daoSignature = signatures[permissionHash];
        bool[6] memory flags = moloch.getProposalFlags(daoSignature.proposalId);
        require(flags[2], ERROR_NOT_PASSED);
        require(daoSignature.signatureHash == keccak256(abi.encodePacked(signature)), 'Invalid signature hash');
        return daoSignature.magicValue;
    }
    
    //  -- Proposal Functions --

    function proposeSignature(
        bytes32 msgHash,
        bytes32 signatureHash,
        bytes4 magicValue,
        string calldata details
    ) external memberOnly returns (uint256) {

        uint256 proposalId = moloch.submitProposal(
            address(this),
            0,
            0,
            0,
            molochDepositToken,
            0,
            molochDepositToken,
            details
        );

        DAOSignature memory sig = DAOSignature({
            proposalId: proposalId,
            signatureHash: signatureHash,
            magicValue: magicValue,
            proposer: msg.sender
        });

        signatures[msgHash] = sig;

        emit ProposeSignature(proposalId, msgHash, msg.sender);
        return proposalId;
    }

    function cancelSignature(bytes32 msgHash) external {
        DAOSignature memory signature = signatures[msgHash];
        require(msg.sender == signature.proposer, "not proposer");
        delete signatures[msgHash];
        emit SignatureCanceled(signature.proposalId, msgHash);
        moloch.cancelProposal(signature.proposalId);
    }
    
    //  -- Proposal Functions --
    
    function proposeAction(
        address[] calldata actionTos,
        uint256[] calldata actionValues,
        bytes[] calldata actionDatas,
        address withdrawToken,
        uint256 withdrawAmount,
        string calldata details
    ) external memberOnly returns (uint256) {

        require(actionTos.length == actionValues.length, ERROR_LENGTH_MISMATCH);
        require(actionTos.length == actionDatas.length, ERROR_LENGTH_MISMATCH);

        uint256 proposalId = moloch.submitProposal(
            address(this),
            0,
            0,
            0,
            molochDepositToken,
            withdrawAmount,
            withdrawToken,
            details
        );

        saveAction(proposalId, actionTos, actionValues, actionDatas, withdrawToken, withdrawAmount );

        return proposalId;
    }

    function saveAction(
        uint256 proposalId,
        address[] calldata actionTos,
        uint256[] calldata actionValues,
        bytes[] calldata actionDatas,
        address withdrawToken,
        uint256 withdrawAmount
        ) internal {
        bytes32 id = hashOperation(actionTos, actionValues, actionDatas);
        Action memory action = Action({
            id: id,
            proposer: msg.sender,
            executed: false,
            token: withdrawToken,
            amount: withdrawAmount
        });
        actions[proposalId] = action;
        for (uint256 i = 0; i < actionTos.length; ++i) {
            emit ProposeAction(id, proposalId, i, actionTos[i], actionValues[i], actionDatas[i]);
        }
        
    }

    function executeAction(
        uint256 proposalId,
        address[] calldata actionTos,
        uint256[] calldata actionValues,
        bytes[] calldata actionDatas) external returns (bool) {
        Action memory action = actions[proposalId];

        bool canExecute = isPassed(proposalId);
        require(canExecute, ERROR_REQS_NOT_MET);

        bytes32 id = hashOperation(actionTos, actionValues, actionDatas);

        if(action.amount > 0) {
            // withdraw token tribute if any
            doWithdraw(action.token, moloch.getUserTokenBalance(address(this), action.token));
        }
        
        require(id == action.id, ERROR_NOT_VALID);
        require(!action.executed, ERROR_EXECUTED);
        
        // execute call
        actions[proposalId].executed = true;
        for (uint256 i = 0; i < actionTos.length; ++i) {
            require(address(this).balance >= actionValues[i], ERROR_FUNDS);
            (bool success, ) = actionTos[i].call{value: actionValues[i]}(actionDatas[i]);
            require(success, ERROR_CALL_FAIL);
            emit ExecuteAction(id, proposalId, i, actionTos[i], actionValues[i], actionDatas[i], msg.sender);
        }
        delete actions[proposalId];

        return true;
    }
    
    function cancelAction(
        uint256 _proposalId) external {
        Action memory action = actions[_proposalId];
        require(msg.sender == action.proposer, ERROR_NOT_PROPOSER);
        delete actions[_proposalId];
        emit ActionCanceled(_proposalId);
        moloch.cancelProposal(_proposalId);
    }

    // admin functions
    function changeOwner(address _moloch) external thisOnly returns (bool) {
        // TODO: should we try to verify this is a moloch contract
        moloch = IMOLOCH(_moloch);
        emit ChangeOwner(_moloch);
        return true;
    }

    function setModule(address _module) external thisOnly returns (bool) {
        module = _module;
        emit SetModule(_module);
        return true;
    }
    
    //  -- Helper Functions --
    
    function isPassed(uint256 _proposalId) internal returns (bool) {
        // if met execution can proceed before proposal is processed
        uint256 totalShares = moloch.totalShares();
        bool[6] memory flags = moloch.getProposalFlags(_proposalId);

        (, , , , , , , , , , uint256 yesVotes, uint256 noVotes) = moloch.proposals(_proposalId);
        
        if (flags[2]) {
            // if proposal has passed dao return true
            return true;
        }

        if(module != address(0) && msg.sender==module){
            // if module is set, proposal is sposored and sender is module
            require(flags[0], ERROR_NOT_SPONSORED);
            return true;
        }

        if (minQuorum != 0) {
            uint256 quorum = yesVotes * 100 / totalShares;
            // if quorum is set it must be met and there can be no NO votes
            return quorum >= minQuorum && noVotes < 1;  
        }
        
        return false;
    }
    function isMember(address user) public view returns (bool) {
        // member only check should check if member or delegate
        address memberAddress = moloch.memberAddressByDelegateKey(user);
        (, uint shares,,,,) = moloch.members(memberAddress);
        return shares > 0;
    }

    function hashOperation(
        address[] calldata targets, 
        uint256[] calldata values, 
        bytes[] calldata datas) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas));
    }

    receive() external payable {}
    fallback() external payable {}
}

contract CloneFactory {
    function createClone(address payable target) internal returns (address payable result) { 
        // eip-1167 proxy pattern adapted for payable minion
        bytes20 targetBytes = bytes20(address(target));
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract NeapolitanMinionFactory is CloneFactory {
    address payable immutable public template; // fixed template for minion using eip-1167 proxy pattern
    address[] public minionList; 
    mapping (address => AMinion) public minions;
    
    event SummonMinion(address indexed minion, address indexed moloch, string details, string minionType, uint256 minQuorum);
    
    struct AMinion {
        address moloch;
        string details; 
    }
    
    constructor(address payable _template) {
        template = _template;
    }
    
    function summonMinion(
        address moloch, 
        string memory details, 
        uint256 minQuorum) external returns (address) {
        NeapolitanMinion minion = NeapolitanMinion(createClone(template));
        require(minQuorum > 0 && minQuorum <= 100, "MinionFactory: minQuorum must be between 1-100");
        minion.init(moloch, minQuorum);
        string memory minionType = "Neapolitan minion";
        
        minions[address(minion)] = AMinion(moloch, details);
        minionList.push(address(minion));
        emit SummonMinion(address(minion), moloch, details, minionType, minQuorum);
        
        return(address(minion));
        
    }
}

contract WhitelistModuleHelper {


    NeapolitanMinion minion;
    mapping (address => bool) public whitelist;
    constructor(address[] memory _whitelist, address payable _minion) {
        for (uint256 i = 0; i < _whitelist.length; i++){
            whitelist[_whitelist[i]] = true;
        }
        minion = NeapolitanMinion(_minion);
    }

    function executeAction(
        uint256 _proposalId,
        address[] calldata _actionTos,
        uint256[] calldata _actionValues,
        bytes[] calldata _actionDatas) public {
        require(whitelist[msg.sender], "Whitelist Module::Not whitelisted");
        minion.executeAction(_proposalId, _actionTos, _actionValues, _actionDatas);
    }
}