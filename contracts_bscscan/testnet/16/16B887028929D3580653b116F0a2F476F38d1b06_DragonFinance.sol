// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


import "./ProposableGroupSystem.sol";
import "./TimeLockableToken.sol";
import "./DragonConstants.sol";
/**
 * AFTER DEPLOY:
 * _setCurrentDeflationAddress(address)
 * _setCurrentDeflationPct(deflationPct)
 * _setCurrentTimeLockManager(address)
 * add other admins
 */
contract DragonFinance is TimeLockableToken, ProposableGroupSystem, DragonConstants {
    using SafeMath for uint256;

    constructor(){
        assert(addGroup(_msgSender())==ADMIN_GROUP);
        setVoterNumberLimit(MAX_ADMIN_NUMBER);
        for(uint8 i=0; i<ACTION_NUMBER; ++i) {
            setActionPct(i, INITIAL_PCTS[i]);
        }
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


/*          ADMIN            */

    /**     PAUSE_TOKEN
     *@dev Lets admin propose token pause
     */
    function Z_pause() external returns (bool) {
        onlyAdmin();
        _executeApprovedProposal(uint8(Action.PAUSE_TOKEN),mapProposalValues(0,address(0),0));       
        return true;
    }
    /**     MANAGE_EXCLUSION (G1)
     *@dev Lets admin propose execution of
     * _setExclusionStatus(`account`, statusMap)
     * generating statusMap from
     * _mapExclusionStatus(`txInExclusion`, `txOutExclusion`, `txInBlacklist`, `txOutBlacklist`)
     * accepted values for params are 0 and 1
     */
    function Z_setExclusionStatus(address account, uint256 txInExclusion, uint256 txOutExclusion, uint256 txInBlacklist, uint256 txOutBlacklist) public returns (bool) {
        onlyAdmin();
        uint256 exclusionMap=_mapExclusionStatus(txInExclusion, txOutExclusion, txInBlacklist, txOutBlacklist);
        _executeApprovedProposal(uint8(Action.MANAGE_EXCLUSION),mapProposalValues(exclusionMap,account,0));       
        return true;
    }
    /**     UNPAUSE_TOKEN (G1)
     *@dev Lets admin propose token unpause
     */
    function Z_unpause() external returns (bool) {
        onlyAdmin();
        _executeApprovedProposal(uint8(Action.UNPAUSE_TOKEN),mapProposalValues(0,address(0),0));       
        return true;
    }
     
    /**     MANAGE_DEFLATION (G2)
     *@dev Lets admin propose execution of _manageDeflation(`account`, `deflationPct`)
     * to update _deflationAddress and _deflationPct
     */
    function Z_manageDeflation(address account, uint8 deflationPct) public returns (bool) {
        onlyAdmin();
        _executeApprovedProposal(uint8(Action.MANAGE_DEFLATION),mapProposalValues(0,account,deflationPct));       
        return true;
    }
    /**     CNG_UNL_MNG_ADDR (G2)
     *@dev Lets admin propose execution of _setCurrentTimeLockManager(`account`)
     * to update _timeLockManager
     */
    function Z_setCurrentTimeLockManager(address account) public returns (bool) {
        onlyAdmin();
        _executeApprovedProposal(uint8(Action.CNG_UNL_MNG_ADDR),mapProposalValues(0,account,0));       
        return true;
    }
    /**     ADD_ADMIN (G2)
     *@dev Lets admin propose execution of addMemberToGroup(`account`)
     *  to add `account` as new admin
     */
    function Z_addAdmin(address account) public returns (bool) {
        onlyAdmin();
        require(isGroupMember(ADMIN_GROUP, account)==false,"BA02");
        _executeApprovedProposal(uint8(Action.ADD_ADMIN),mapProposalValues(0,account,0));       
        return true;
    }
    /**     ADD_ADMIN (G2)
     *@dev Lets admin propose execution of addMemberToGroup(`account`)
     *  to add `account` as new admin
     */
    function Z_changeAdmin(address account) public returns (bool) {
        onlyAdmin();
        require(isGroupMember(ADMIN_GROUP, account)==false,"BA02");
        if(getGroupMemberNumber(ADMIN_GROUP)>1){
            removeMemberFromGroup(ADMIN_GROUP, _msgSender());
            addMemberToGroup(ADMIN_GROUP,account); 
        }else{
            addMemberToGroup(ADMIN_GROUP,account); 
            removeMemberFromGroup(ADMIN_GROUP, _msgSender());
        }
        return true;
    }
    /**     REMOVE_ADMIN (G3)
     *@dev Lets admin propose execution of removeMemberFromGroup(`account`)
     *  to add `account` as new admin
     */
    function Z_removeAdmin(address account) public returns (bool) {
        onlyAdmin();
        require(isGroupMember(ADMIN_GROUP, account)==true,"BA01");
        _executeApprovedProposal(uint8(Action.REMOVE_ADMIN),mapProposalValues(0,account,0));       
        return true;
    }
    /**     MINT_TOKEN (G3)
     *@dev Lets admin propose execution of _mint(`account`,`value`);
     * to increase token _totalSupply
     * _totalSupply cannot be higher than INITIAL_SUPPLY
     */
    function Z_mintToken(address account, uint256 value) public returns (bool) {
        onlyAdmin();
        _executeApprovedProposal(uint8(Action.MINT_TOKEN),mapProposalValues(value,account,0));
        return true;
    }
    /**
     * Propose percentage variation for one of following `actionGroup`:
     * - 0: PAUSE_TOKEN as CNG_PAUSE_PCT
     * - 1: G1 as CNG_G1_PCT
     * - 2: G2 as CNG_G1_PCT
     * - 3: G3 as CNG_G1_PCT
     * - 4: all management percentages as CNG_GLB_MNG_PCT
     */
    function Z_setActionPct(uint8 actionGroup, uint8 pct) public returns (bool) {
        onlyAdmin();
        require(actionGroup<5,"BP02");
        _executeApprovedProposal(uint8(Action.CNG_PAUSE_PCT)+actionGroup,mapProposalValues(0,address(0),pct));
        return true;
    }
    
/*           TOKEN TOOLS             */

    //execute approved actions
    function _executeApprovedProposal(uint8 action, Proposed memory values) internal returns (bool) {
        if(Action(action)==Action.PAUSE_TOKEN){                         //PAUSE_TOKEN
            _pause();
        }else if(Action(action)==Action.MANAGE_EXCLUSION){              //MANAGE_EXCLUSION
            return _setExclusionStatus(values.account,values.amount);
        }else if(Action(action)==Action.UNPAUSE_TOKEN){                 //UNPAUSE_TOKEN
            _unpause();
        }else if(Action(action)==Action.MANAGE_DEFLATION){              //MANAGE_DEFLATION
            return _manageDeflation(values.account,values.pct);
        }else if(Action(action)==Action.CNG_UNL_MNG_ADDR){              //CNG_UNL_MNG_ADDR
            return _setCurrentTimeLockManager(values.account);
        }else if(Action(action)==Action.ADD_ADMIN){                     //ADD_ADMIN
            return addMemberToGroup(ADMIN_GROUP,values.account);
        }else if(Action(action)==Action.REMOVE_ADMIN){                  //REMOVE_ADMIN
            return removeMemberFromGroup(ADMIN_GROUP, values.account);
        }else if(Action(action)==Action.MINT_TOKEN){                    //MINT_TOKEN
            _mint(values.account,values.amount);
        }else if(Action(action)==Action.CNG_PAUSE_PCT){                 //CNG_PAUSE_PCT
            setActionPct(uint8(Action.PAUSE_TOKEN),values.pct);
        }else if(Action(action)==Action.CNG_G1_PCT){                    //CNG_G1_PCT
            setActionPct(uint8(Action.MANAGE_EXCLUSION),values.pct);
            setActionPct(uint8(Action.UNPAUSE_TOKEN),values.pct);
        }else if(Action(action)==Action.CNG_G2_PCT){                    //CNG_G2_PCT
            setActionPct(uint8(Action.MANAGE_DEFLATION),values.pct);
            setActionPct(uint8(Action.CNG_UNL_MNG_ADDR),values.pct);
            setActionPct(uint8(Action.ADD_ADMIN),values.pct);
        }else if(Action(action)==Action.CNG_G3_PCT){                    //CNG_G3_PCT
            setActionPct(uint8(Action.REMOVE_ADMIN),values.pct);
            setActionPct(uint8(Action.MINT_TOKEN),values.pct);
        }else if(Action(action)==Action.CNG_GLB_MNG_PCT){               //CNG_GLB_MNG_PCT
            setActionPct(uint8(Action.CNG_PAUSE_PCT),values.pct);
            setActionPct(uint8(Action.CNG_G1_PCT),values.pct);
            setActionPct(uint8(Action.CNG_G2_PCT),values.pct);
            setActionPct(uint8(Action.CNG_G3_PCT),values.pct);
        }else{                                                          //Invalid action.
            revert("BP00");
        }
        return true;
    }
}