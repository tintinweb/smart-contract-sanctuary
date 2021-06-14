// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "OZ.sol";

abstract contract BasicAccessControl {
    
    constructor() {
        adminAddress = msg.sender;
    }
    
    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public adminAddress;

    /// @dev Access modifier for Admin-only functionality
    modifier onlyAdmin() {
        require(msg.sender == adminAddress || tx.origin == adminAddress);
        _;
    }

    /// @dev Assigns a new address to act as Admin. Only available to the current Admin.
    /// @param _newAdmin The address of the new Admin
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));

        adminAddress = _newAdmin;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by Admin role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by Admin.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyAdmin whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
    
    /// @dev Withdraw 
    function withdraw() external onlyAdmin {
        // withdraws balance to admin
        payable(adminAddress).transfer(address(this).balance);
    }

    /*** HELPER FUNCTIONS ***/
    /// @dev checks if required parameters are set for the contract
    function _checkFee(uint256 _fee) internal view returns(bool) {
        if(_fee > 0) {
            require( msg.value >= _fee, "Value less than fee" );
        }
        return(true);
        //return ( (_fee == 0 && msg.value == 0) || (registratorAddress != address(0) && msg.value >= _fee ));
    }
    
    /// @dev if fee is set it is ayed to registrator address
    function _payFee(uint256 _fee) internal {
        if(_fee > 0) {
            if(msg.value > _fee) {
                // return any exesss ether back to the sender
                payable(msg.sender).transfer(msg.value - _fee);
            }
        }
    }
}

/// @title Base contract for PlanetaryRegistry. Holds all common structs, events and base variables.
abstract contract WordsRegistry is ERC721, ERC721Burnable, BasicAccessControl {

    /*** EVENTS ***/

    /// @dev The Words event is fired whenever a new object is created. 
    event Words(address indexed owner, string indexed words, string indexed author, uint64 dob);

    struct Word {
        uint64 id;
        string words;
        string author;
        uint64 dob;
    }

    /*** STORAGE ***/
    string public baseTokenUri;

    /// @dev An array containing the Plot struct for all plots in existence. 
    mapping(uint256 => Word) public words;
    uint64 public maxId;

    /*** FEES ***/
    uint256 public fee = 0.0005 ether;

    function _baseURI() internal view override returns (string memory) {
        return baseTokenUri;
    }
    
    /*** VALIDATORS ***/
    /// @dev checks that plot in owned by message sender
    function _owns(uint256 _tokenId) internal view returns(bool) {
        return (msg.sender == ERC721.ownerOf(_tokenId));
    }
    
    /*** SETTERS ***/
    function setBaseTokenUri(string memory _baseTokenUri) external onlyAdmin {
        baseTokenUri = _baseTokenUri;
    }

    // @dev sets new price for adding plot to estate
    function setFee(uint256 _value) external onlyAdmin {
        fee = _value;
    }
    
    /*** HELPER FUNCTIONS ***/
    function _storeWords(Word memory _word) internal returns(uint256) {
        maxId++;
        _word.id = maxId;
        words[maxId] = _word;
        return maxId;
        
    }
    
    function _getWord(uint256 _id) internal view returns(Word storage) {
        return words[_id];
    }

    /*** FRONTEND LOGIC ***/
    // @dev New Word register.
    function memorialize(
        string memory _words,
        string memory _author,
        uint64 _dob
    )
        external
        payable
        returns (uint256)
    {


        require( _checkFee(fee) );

        Word memory _word = Word({
            id: 0,
            words: _words,
            author: _author,
            dob: _dob
        });

        uint256 _id = _storeWords(
            _word
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _mint(msg.sender, _id);
        
        emit Words(
            msg.sender,
            _words,
            _author,
            _dob
        );

        _payFee( fee );
        
        return _id;
    }

}

contract EternalWordsNFT is WordsRegistry {
    
    /*** CONSTRUCTOR ***/
    constructor() ERC721("EternalWordsMatter", "WORDS") {
        baseTokenUri = "https://eternalwordsmatter.org/metadata/";
    }

}