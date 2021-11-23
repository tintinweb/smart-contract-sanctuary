// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "./ERC721.sol";
import "./Ownable.sol";
import "./ILendingTemplate.sol";


/**
 * @title StaterPromissoryNote
 * @dev Implementats wrapping/unwrapping process of stater loans
 * @author Stater
 */ 
contract StaterPromissoryNote is ERC721, Ownable {
    
        
    /* ****** */
    /* EVENTS */
    /* ****** */
    
    /// @dev This event is fired when a user creates a new promissory note
    event WrapLoansAndMintPromissoryNote(uint256 indexed promissoryNoteId);
    
    
    /* ******* */
    /* STORAGE */
    /* ******* */
    struct PromissoryNote {
        uint256[] loans; //list of approved loans
        address payable owner;
    }
    mapping(uint256 => PromissoryNote) public promissoryNotes;
    mapping(uint256 => uint256) public promissoryLoans;
    
    /// @dev It needs to start with 1 so 0 can be used as "no promissory note assigned" status on the lending smart contract
    uint256 public promissoryNoteId = 1;
    ILendingTemplate public lendingDataTemplate;
    
    /* ********* */
    /* CONSTANTS */
    /* ********* */

	//TODO: change the uri after the api implementation
	// Add the lendingDataAddress using the setter, no longer supported on smart contract constructor
    constructor(string memory name, string memory symbol) ERC721(name,symbol) { }
    
    /* ********* */
    /* FUNCTIONS */
    /* ********* */
    
    /**
     * @dev Allows a user to lock approved loans in the contract and mint a new Promissory Note 
     */ 
    function createPromissoryNote(uint256[] calldata loanIds) external {
        require(loanIds.length > 0, "You must submit an array with at least one element");
        
        //Allow loans to be used in the Promissory Note
        require(address(lendingDataTemplate) != address(0),"Lending contract not established");
        
        //Set promissory note fields
        promissoryNotes[promissoryNoteId].loans = loanIds;
        promissoryNotes[promissoryNoteId].owner = msg.sender;
        
        for (uint i = 0; i < loanIds.length; ++i){
            require(promissoryLoans[loanIds[i]] == 0,"One of the loans is already used by another promissory note");
            require(lendingDataTemplate.getPromissoryPermission(loanIds[i]) == msg.sender);
            promissoryLoans[loanIds[i]] = promissoryNoteId;
        }
        
        //mint promissory note
        _safeMint(msg.sender, promissoryNoteId, "");
    
        emit WrapLoansAndMintPromissoryNote(promissoryNoteId);
        ++promissoryNoteId;
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    )
        public
        override
    {
        safeTransferFrom(from,to,id,"");
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory _data
    )
        public
        override
    {
    	require(address(lendingDataTemplate) != address(0),"Lending contract not established");
        require(id < promissoryNoteId, "Invalid promissory ID");

	    //Allow loans to be used in the Promissory Note
	    super.safeTransferFrom(from,to,id,_data);

        lendingDataTemplate.promissoryExchange(from,payable(to),promissoryNotes[id].loans);
        promissoryNotes[id].owner = payable(to);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 id
    )
        public
        override
    {
     	require(address(lendingDataTemplate) != address(0),"Lending contract not established");
        require(id < promissoryNoteId, "Invalid promissory ID");

        //Allow loans to be used in the Promissory Note
	    super.transferFrom(from,to,id);
        
        lendingDataTemplate.promissoryExchange(from,payable(to),promissoryNotes[id].loans);
        promissoryNotes[id].owner = payable(to);
    }
    
    /**
     * @notice Setter function for the main Stater lending contract
     * @param _lendingDataAddress The address of the stater lending contract
     */ 
    function setLendingDataAddress(address _lendingDataAddress) external onlyOwner {
        lendingDataTemplate = ILendingTemplate(_lendingDataAddress);
    }
    
    function _burn(uint256 _promissoryNoteId) internal override {
        super._burn(_promissoryNoteId);
    }
    
    function burnPromissoryNote(uint256 _promissoryNoteId) external {
        require(promissoryNotes[_promissoryNoteId].owner == msg.sender, "You're not the owner of this promissory note");
        _burn(_promissoryNoteId);
        for (uint i = 0; i < promissoryNotes[_promissoryNoteId].loans.length; ++i)
            promissoryLoans[promissoryNotes[_promissoryNoteId].loans[i]] = 0;
        delete promissoryNotes[_promissoryNoteId];
    }
    
}