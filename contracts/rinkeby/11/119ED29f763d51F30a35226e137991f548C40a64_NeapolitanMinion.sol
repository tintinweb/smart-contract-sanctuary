/**
 *Submitted for verification at Etherscan.io on 2021-08-13
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
    string private constant ERROR_DELETED = "Minion::action was deleted";
    string private constant ERROR_FUNDS = "Minion::insufficient native token";
    string private constant ERROR_CALL_FAIL = "Minion::call failure";
    string private constant ERROR_NOT_WL = "Minion::not a whitelisted token";
    string private constant ERROR_TX_FAIL = "Minion::token transfer failed";
    string private constant ERROR_NOT_PROPOSER = "Minion::not proposer";
    string private constant ERROR_THIS_ONLY = "Minion::can only be called by this";
    string private constant ERROR_MEMBER_ONLY = "Minion::not member";
    string private constant ERROR_MEMBER_OR_MODULE_ONLY = "Minion::not member or module";
    string private constant ERROR_NOT_SPONSORED = "Minion::proposal not sponsored";
    string private constant ERROR_NOT_PASSED = "Minion::proposal has not passed";
    string private constant ERROR_MOLOCH_CHANGED = "Minion::moloch has been changed";
    string private constant ERROR_MIN_QUORUM_BOUNDS = "Minion::minQuorum must be 0 to 100";
    string private constant ERROR_ZERO_DEPOSIT_TOKEN = "Minion:zero deposit token is not allowed";
    string private constant ERROR_MOLOCH_SHARES = "Minion:moloch must have no members with shares";
    string private constant ERROR_NO_ACTION = "Minion:action does not exist";
    struct Action {
        bytes32 id;
        address proposer;
        bool executed;
        address token;
        uint256 amount;
        address moloch;
        bool memberOrModule; // 0 anyone , 1 memberOrModuleOnly
    }

    mapping (bytes32 => DAOSignature) public signatures; // msgHash => Signature
    struct DAOSignature {
        bytes32 signatureHash;
        bytes4 magicValue;
    }

    event ProposeNewAction(bytes32 indexed id, uint256 indexed proposalId, address withdrawToken, uint256 withdrawAmount, address moloch, bool memberOrModule);
    event ProposeAction(bytes32 indexed id, uint256 indexed proposalId, uint256 index, address target, uint256 value, bytes data);
    event ExecuteAction(bytes32 indexed id, uint256 indexed proposalId, uint256 index, address target, uint256 value, bytes data, address executor);
    event ExecuteEscapeHatch(address target, uint256 value, bytes data, address executor);
    
    event DoWithdraw(address token, uint256 amount);
    event CrossWithdraw(address target, address token, uint256 amount);
    event PulledFunds(address moloch, uint256 amount);
    event ActionCanceled(uint256 proposalId);
    event ActionDeleted(uint256 proposalId);

    event ProposeSignature(uint256 proposalId, bytes32 msgHash, address proposer);
    event SignatureCanceled(uint256 proposalId, bytes32 msgHash);
    event ExecuteSignature(uint256 proposalId, address executor);

    event ChangeOwner(address owner);
    event SetModule(address module);
    
    modifier memberOnly() {
        require(isMember(msg.sender), ERROR_MEMBER_ONLY);
        _;
    }

    modifier memberOrModuleOnly() {
        require(isMember(msg.sender) || msg.sender == module, ERROR_MEMBER_OR_MODULE_ONLY);
        _;
    }

    modifier thisOnly() {
        require(msg.sender == address(this), ERROR_THIS_ONLY);
        _;
    }

    modifier noMemberMoloch() {
        require(moloch.totalShares() < 1, ERROR_MOLOCH_SHARES);
        _;
    }

    function init(address _moloch, uint256 _minQuorum) external {
        require(!initialized, ERROR_INIT); 
        // min quorum must be between 0% and 100%, if 0 early execution is disabled
        require(_minQuorum >= 0 && _minQuorum <= 100, ERROR_MIN_QUORUM_BOUNDS);
        moloch = IMOLOCH(_moloch);
        minQuorum = _minQuorum;
        molochDepositToken = moloch.depositToken();
        // verify that moloch address has a deposit token and it is not zero
        // require(molochDepositToken != address(0), ERROR_ZERO_DEPOSIT_TOKEN);
        initialized = true; 
        emit ChangeOwner(_moloch);
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
    
    //  -- Moloch Withdraw Functions --
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
        external
        view
        override
        returns (bytes4)
    {
        DAOSignature memory daoSignature = signatures[permissionHash];
        require(daoSignature.magicValue != 0, "erc1271::invalid signature");
        require(
            daoSignature.signatureHash ==
                keccak256(abi.encodePacked(signature)),
            "erc1271::invalid signature hash"
        );
        return daoSignature.magicValue;
    }

    function sign(
        bytes32 permissionHash,
        bytes32 signatureHash,
        bytes4 magicValue
    ) external thisOnly {
        signatures[permissionHash] = DAOSignature({
            signatureHash: signatureHash,
            magicValue: magicValue
        });
    }

    
    //  -- Proposal Functions --
    function proposeAction(
        address[] calldata actionTos,
        uint256[] calldata actionValues,
        bytes[] calldata actionDatas,
        address withdrawToken,
        uint256 withdrawAmount,
        string calldata details,
        bool memberOrModule
    ) external memberOrModuleOnly returns (uint256) {

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

        saveAction(proposalId, actionTos, actionValues, actionDatas, withdrawToken, withdrawAmount, memberOrModule );

        return proposalId;
    }

    // if the parent moloch has no share holding members this can be used to release funds
    function escapeHatch(
        address actionTo,
        uint256 actionValue,
        bytes calldata actionData
    ) external noMemberMoloch returns (bool) {
        require(address(this).balance >= actionValue, ERROR_FUNDS);
        (bool success, ) = actionTo.call{value: actionValue}(actionData);
        require(success, ERROR_CALL_FAIL);
        emit ExecuteEscapeHatch(actionTo, actionValue, actionData, msg.sender);
        return true;
    }
    
    function deleteAction(uint256 _proposalId) external thisOnly returns (bool) {
        //TODO: can delete own proposal, how to check?
        // check action exists
        require(actions[_proposalId].proposer != address(0), ERROR_NO_ACTION);
        delete actions[_proposalId];
        emit ActionDeleted(_proposalId);
        return true;
    }

    function saveAction(
        uint256 proposalId,
        address[] calldata actionTos,
        uint256[] calldata actionValues,
        bytes[] calldata actionDatas,
        address withdrawToken,
        uint256 withdrawAmount,
        bool memberOrModule
        ) internal {
        bytes32 id = hashOperation(actionTos, actionValues, actionDatas);
        Action memory action = Action({
            id: id,
            proposer: msg.sender,
            executed: false,
            token: withdrawToken,
            amount: withdrawAmount,
            moloch: address(moloch),
            memberOrModule: memberOrModule
        });
        actions[proposalId] = action;
        emit ProposeNewAction(id, proposalId, withdrawToken, withdrawAmount, address(moloch), memberOrModule);
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
        require(!action.executed, ERROR_EXECUTED);

        if(action.memberOrModule) {
            require(isMember(msg.sender) || msg.sender == module, ERROR_MEMBER_OR_MODULE_ONLY);
        }

        require(isPassed(proposalId), ERROR_REQS_NOT_MET);
        require(action.id != 0, ERROR_DELETED);
        require(action.moloch == address(moloch), ERROR_MOLOCH_CHANGED);

        bytes32 id = hashOperation(actionTos, actionValues, actionDatas);

        require(id == action.id, ERROR_NOT_VALID);
        

        if(action.amount > 0 && moloch.getUserTokenBalance(address(this), action.token) > 0) {
            // withdraw token tribute if any
            doWithdraw(action.token, moloch.getUserTokenBalance(address(this), action.token));
        }
        
        // execute calls
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

    // -- Admin Functions --
    function changeOwner(address _moloch) external thisOnly returns (bool) {
        // TODO: withdraw any funds from dao first? may need to verify this on the front end
        moloch = IMOLOCH(_moloch);
        molochDepositToken = moloch.depositToken();
        // verify that moloch address has a deposit token and it is not zero
        require(molochDepositToken != address(0), ERROR_ZERO_DEPOSIT_TOKEN);
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
        uint256 totalShares = moloch.totalShares();
        bool[6] memory flags = moloch.getProposalFlags(_proposalId);
        require(flags[0], ERROR_NOT_SPONSORED);

        // if any of these branches are true, let action proceed before proposal is processed
        if (flags[2]) {
            // if proposal has passed dao return true
            return true;
        }

        if(module != address(0) && msg.sender==module){
            // if module is set, proposal is sposored and sender is module
            return true;
        }
        
        if (minQuorum != 0) {
            (, , , , , , , , , , uint256 yesVotes, uint256 noVotes) = moloch.proposals(_proposalId);
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

    fallback() external payable {}
    receive() external payable {}
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
    string public constant minionType = "Neapolitan minion";
    
    event SummonMinion(address indexed minion, address indexed moloch, string details, string minionType, uint256 minQuorum);
    
    struct AMinion {
        address moloch;
        string details; 
    }
    
    constructor(address payable _template, address _molochTemplate) {
        template = _template;
        NeapolitanMinion minion = NeapolitanMinion(_template); 
        minion.init(_molochTemplate,0);
    }
    
    function summonMinion(
        address moloch, 
        string memory details, 
        uint256 minQuorum) external returns (address) {
        NeapolitanMinion minion = NeapolitanMinion(createClone(template));
        minion.init(moloch, minQuorum);
        
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