// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


import "./ProposableGroupSystem.sol";
import "./WrappableToken.sol";
import "./wBTCzConstants.sol";


contract wBTCz is WrappableToken, ProposableGroupSystem, wBTCzConstants{    
    using SafeMath for uint256;

    constructor() {
        assert(addGroup(_msgSender())==ADMIN_GROUP);
        setVoterNumberLimit(MAX_ADMIN_NUMBER);  // FRED.EF sets the maximum number of members for the admin group
        // TODO MAYBE trasferire in una funzione apposita (che però viene chiamata soltanto una volta e basta) FRED.EF
        for(uint8 i=0; i<ACTION_NUMBER; ++i) {
            setActionPct(i, INITIAL_PCTS[i]);
        }

        // TODO remove - debug function to be used in testing
        _changeMintingAddress(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);  // FRED.EF da sostituire con un qualunque indirizzo remix per easy debugging
    }

/*          MODIFIERS            */
    // modifiers use too much bytecode

    function onlyAdmin() internal view {
        require(isGroupMember(ADMIN_GROUP, _msgSender())==true,"BA01");
    }


/*          VIEWS            */

    // EXTERNAL returns admins accounts
    function getAdmins() external view returns (address[] memory){
        return getGroupMembers(ADMIN_GROUP);
    }

    // EXTERNAL check if account is admin
    function isAdmin(address account) external view returns (bool) {
        return  isGroupMember(ADMIN_GROUP, account);
    }
    
    // EXTERNAL returns minting address
    function getMintingAddress() external view returns (address) {
        return _getMintingAddress();
    }

    /*       STANDARD VIEWS       */

    // EXTERNAL returns caller balance
    function myBalance() external view returns (uint256) {
        return balanceOf(_msgSender());
    }
/*          Z ADMIN            */

    // EXTERNAL delete proposal made by caller using action index
    function ZDeleteProposal(uint8 action) external returns (bool){
        onlyAdmin();
        removeProposal(_msgSender(), action);
        return true;
    }

    // EXTERNAL get proposal using proposal index
    function ZGetProposal(uint256 proposalIndex) external view returns (
        address proposer,
        string memory description,
        uint8 minPositive,
        uint8 minNegative,
        string memory result,
        uint256 valueU,
        address valueA
    ){
        onlyAdmin();
        uint256 value;
        uint8 action;
        int8 resultValue;
        value=getProposal[proposalIndex].value;
        proposer=getProposal[proposalIndex].proposer;
        action=getProposal[proposalIndex].action;
        minPositive=getProposal[proposalIndex].minPositive;
        minNegative=getProposal[proposalIndex].minNegative;
        resultValue=getProposal[proposalIndex].result;
        
        require(minPositive>0,"BP01");
        result=ResultString[uint8(resultValue+1)];
        ActionValueType actionValueType=_getActionType(action);
        if(actionValueType==ActionValueType.ADDRESS){
            valueA=address(uint160(value));
        }else{
            valueU=value;
        }
        description=ActionString[action];
    }

    //
    function ZGetProposalIndex(address proposer, uint8 action) external view returns (
        uint256 proposalIndex
    ){
        onlyAdmin();
        proposalIndex=getAddressProposalIndex[proposer][action];
    }
    // EXTERNAL get action using action index
    function ZGetAction(uint8 action) external view returns (
        uint8 pct,
        string memory description,
        string memory valueType
    ){
        onlyAdmin();
        require(action<ActionString.length,"BP02");
        pct=getActionPct(action);
        description=ActionString[action];
        valueType=ActionValueTypeString[uint8(_getActionType(action))];
    }
    
    // EXTERNAL propose a value to a specific action
    function ZPropose(uint8 action, uint256 value) external returns (bool) {
        onlyAdmin();
        _submitProposal(_msgSender(), action, value);
        return true;
    }
    /*          EXTERNALS            */
    function ZProposePause() external {
        onlyAdmin();
        whenNotPaused();
        _submitProposal(_msgSender(), uint8(Action.PAUSE_TOKEN), 1);
    }
    function ZProposeUnpause() external {
        onlyAdmin();
        whenPaused();
        _submitProposal(_msgSender(), uint8(Action.UNPAUSE_TOKEN), 1);
    }
/*
    // EXTERNAL propose an address to a specific action
    function ZProposeAddress(uint8 action, uint256 value) external returns (bool) {
        onlyAdmin();
        require(_getActionType(action)==ActionValueType.ADDRESS,"Action require value");
        _submitProposal(_msgSender(), action, uint256(uint160(value)));
        return true;
    }

    // EXTERNAL propose a value to a specific action
    function ZProposeValue(uint8 action, uint256 value) external returns (bool) {
        onlyAdmin();
        require(_getActionType(action)!=ActionValueType.ADDRESS,"Action require address");
        _submitProposal(_msgSender(), action, value);
        return true;
    }
*/
    //      vote
    function ZVote(uint256 proposalIndex, uint8 decision) external returns (bool) {
        onlyAdmin();
        _voteProposal(_msgSender(), proposalIndex, decision);
        return true;
    }

/*          TOKEN TOOLS            */
    
    // INTERNAL transfer from user1 to user2
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != _getMintingAddress(), "BT03");
        require(recipient != _getMintingAddress(), "BT04");

        super._transfer(sender, recipient, amount);
    }
	
/*          ADMINISTRATIVE TOOLS            */


/*              EVENTS DEFINITION       */

    event New_proposal(uint256 indexed proposalIndex, address indexed from, string action, uint256 value);
    event New_proposal(uint256 indexed proposalIndex, address indexed from, string action, address account);

    event Deleted_proposal(uint256 indexed proposalIndex, address indexed from, string action);

    event Approved_proposal(uint256 indexed proposalIndex, address indexed from, string action, uint256 value);
    event Approved_proposal(uint256 indexed proposalIndex, address indexed from, string action, address account);
    
    event Denied_proposal(uint256 indexed proposalIndex, address indexed from, string action, uint256 value);
    event Denied_proposal(uint256 indexed proposalIndex, address indexed from, string action, address account);


/*              EVENTS EMITTAL          */
    function _emitNewProposal(uint256 proposalIndex, address proposer, uint8 actionIndex, uint256 value) internal {
        if(_getActionType(actionIndex)==ActionValueType.ADDRESS){
            emit New_proposal(proposalIndex, proposer, ActionString[actionIndex], address(uint160(value)));
        }else{
            emit New_proposal(proposalIndex, proposer, ActionString[actionIndex], value);
        }
    }
    
    function _emitDeniedProposal(uint256 proposalIndex, address proposer, uint8 actionIndex, uint256 value) internal {
        if(_getActionType(actionIndex)==ActionValueType.ADDRESS){
            emit Denied_proposal(proposalIndex, proposer, ActionString[actionIndex], address(uint160(value)));
        }else{
            emit Denied_proposal(proposalIndex, proposer, ActionString[actionIndex], value);
        }
    }
    
    function _emitApprovedProposal(uint256 proposalIndex, address proposer, uint8 actionIndex, uint256 value) internal {
        if(_getActionType(actionIndex)==ActionValueType.ADDRESS){
            emit Approved_proposal(proposalIndex, proposer, ActionString[actionIndex], address(uint160(value)));
        }else{
            emit Approved_proposal(proposalIndex, proposer, ActionString[actionIndex], value);
        }
    }

/*           TOKEN TOOLS             */

    //execute approved actions
    function _executeApprovedProposal(uint8 action, uint256 value) internal returns (bool) {

        if(Action(action)==Action.ADD_ADMIN){
            //if(getGroupMemberNumber(ADMIN_GROUP)>=50){return false;}
            //commented function implemented in ProposableGroupSystem.beforeAddingMemberToGroup
            return addMemberToGroup(ADMIN_GROUP,address(uint160(value)));
        }else if(Action(action)==Action.REMOVE_ADMIN){
            address oldAdmin=address(uint160(value));
            return removeMemberFromGroup(ADMIN_GROUP, oldAdmin);
        }else if(Action(action)==Action.MINT_TOKEN){
            _mint(_getMintingAddress(),value);
        }else if(Action(action)==Action.BURN_TOKEN){
            _burn(_getMintingAddress(),value);
        }else if(Action(action)==Action.MINTING_ADDRESS){
            _changeMintingAddress(address(uint160(value)));
        }else if(Action(action)==Action.PAUSE_TOKEN){
            _pause();   // FRED.EF
        }else if(Action(action)==Action.UNPAUSE_TOKEN){
            _unpause();   // FRED.EF
        }else if(Action(action)==Action.CHANGE_ADMIN_PCT){
            setActionPct(uint8(Action.ADD_ADMIN),uint8(value));
            setActionPct(uint8(Action.REMOVE_ADMIN),uint8(value));
            setActionPct(uint8(Action.MINTING_ADDRESS),uint8(value));
            setActionPct(uint8(Action.PAUSE_TOKEN),uint8(value));
        }else if(Action(action)==Action.CHANGE_TOKEN_PCT){
            setActionPct(uint8(Action.MINT_TOKEN),uint8(value));
            setActionPct(uint8(Action.BURN_TOKEN),uint8(value));
        }else if(Action(action)==Action.MANAGEMENT_PCT){
            setActionPct(uint8(Action.CHANGE_ADMIN_PCT),uint8(value));
            setActionPct(uint8(Action.CHANGE_TOKEN_PCT),uint8(value));
        }else{
            revert("BP00");
        }
        return true;
    }

    function _getActionTypeFromProposal(uint256 proposalIndex) internal view returns (ActionValueType) {
        uint8 actionIndex=getProposal[proposalIndex].action;
        return _getActionType(actionIndex);
    }

    function _getActionType(uint8 action) internal view returns (ActionValueType) {
        //uint8 actionIndex=_proposal.getProposalAction(proposalIndex);
        //return ActionsAddress[actionIndex];
        require(action<ActionString.length,"Invalid action");
        Action actionIndex=Action(action);

        if(
            actionIndex==Action.MINT_TOKEN ||
            actionIndex==Action.BURN_TOKEN
        ){
            return ActionValueType.AMOUNT;
        }else if(
            actionIndex==Action.ADD_ADMIN ||
            actionIndex==Action.REMOVE_ADMIN ||
            actionIndex==Action.MINTING_ADDRESS
        ){
            return ActionValueType.ADDRESS;
        }else {// if(
            //actionIndex==Action.ADMIN_PCT ||
            //actionIndex==Action.TOKEN_PCT || 	
            //actionIndex==Action.MANAGEMENT_PCT ||
            //actionIndex==Action.PAUSE_TOKEN ||
            //actionIndex==Action.UNPAUSE_TOKEN
            //){
            return ActionValueType.PCT;
        }
    }

    function _submitProposal(
        address proposedBy,
        uint8 action,
        uint256 value) internal {
            if(_getActionType(action)==ActionValueType.PCT){
                require(isPct(value)==true,"BP10");
            }else{
                require(value>0,"BA00");
                //if(Action(action)==Action.ADD_ADMIN){
                //}
            }
            (uint256 proposalIndex, ErrNo errNo)=addProposal(proposedBy, action, ADMIN_GROUP, value);
            require(errNo==ErrNo.OK, ErrNoString[uint256(errNo)]);
            _emitNewProposal(proposalIndex, proposedBy, action, value);
        }

    // INTERNAL vote
    function _voteProposal(address voter, uint256 proposalIndex, uint8 decision) internal {
        (int8 result, ErrNo errNo)=voteProposal(voter, proposalIndex, decision);
        require(errNo==ErrNo.OK, ErrNoString[uint256(errNo)]);
        uint256 value;
        address proposer;
        uint8 action;
        value=getProposal[proposalIndex].value;
        proposer=getProposal[proposalIndex].proposer;
        action=getProposal[proposalIndex].action;
        
        ActionValueType actionValueType;
        actionValueType=_getActionType(action);
        if(result==1){
            bool executed=_executeApprovedProposal(action, value);
            if(executed==true){
                _emitApprovedProposal(proposalIndex, proposer, action, value);
            }else{
                _emitDeniedProposal(proposalIndex, proposer, action, value);
                removeProposal(proposer, action);
            }
            removeProposal(proposer, action);
        }else if(result==-1){
            _emitDeniedProposal(proposalIndex, proposer, action, value);
            removeProposal(proposer, action);
        }
    }

    // Flush proposals made by admin before his removal 
    function beforeRemovingMemberFromGroup(uint256 groupIndex, address account) internal override {
        for(uint8 h=0; h<ActionString.length; ++h){
            removeProposal(account,h);
        }
    }

}