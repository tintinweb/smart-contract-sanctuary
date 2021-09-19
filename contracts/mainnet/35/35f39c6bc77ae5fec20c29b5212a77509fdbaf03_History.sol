/** 
 * ██████╗██╗  ██╗██████╗
 *   ██╔═╝██║  ██║██╔═══╝
 *   ██║  ███████║█████╗
 *   ██║  ██╔══██║██╔══╝
 *   ██║  ██║  ██║██████╗
 *   ╚═╝  ╚═╝  ╚═╝╚═════╝
 * ██╗  ██╗██╗██████╗██████╗███████╗██████╗ ██╗██████╗ █████╗ ██╗
 * ██║  ██║██║██╔═══╝  ██╔═╝██╔══██║██╔══██╗██║██╔═══╝██╔══██╗██║
 * ███████║██║██████╗  ██║  ██║  ██║███████║██║██║    ███████║██║
 * ██╔══██║██║╚═══██║  ██║  ██║  ██║██╔═██╔╝██║██║    ██╔══██║██║
 * ██║  ██║██║██████║  ██║  ███████║██║ ╚██╗██║██████╗██║  ██║██████╗
 * ╚═╝  ╚═╝╚═╝╚═════╝  ╚═╝  ╚══════╝╚═╝  ╚═╝╚═╝╚═════╝╚═╝  ╚═╝╚═════╝
 * ██████╗ ██████╗██████╗███████╗██████╗ ██████╗
 * ██╔══██╗██╔═══╝██╔═══╝██╔══██║██╔══██╗██╔══██╗
 * ███████║█████╗ ██║    ██║  ██║███████║██║  ██║
 * ██╔═██╔╝██╔══╝ ██║    ██║  ██║██╔═██╔╝██║  ██║
 * ██║ ╚██╗██████╗██████╗███████║██║ ╚██╗██████╔╝
 * ╚═╝  ╚═╝╚═════╝╚═════╝╚══════╝╚═╝  ╚═╝╚═════╝
 *  - On-Chain - Immutable - Unstoppable -                   by TheHistoricalRecord.ETH
 * 
 * The Historical Record is an on-chain record of history written by you.
 * 
 * 
 * Anyone can mint a Historical Record and submit a record statement by paying a fee.
 * There can only be one Historical Record for each date, and each Historical Record 
 * is restricted to 10 statements. The statements are stored permanently and immutable 
 * on the Ethereum blockchain.
 * 
 * The initial minter may submit a statement, and each subsequent owner may submit a
 * statement, until the Historical Record is complete (i.e., 10 statements submitted).
 * There is no fee to submit the first statement. A statement fee is required to submit
 * each subsequent statement.
 * 
 * Historical Records can only be minted for dates through the current block timestamp.
 * In other words, dates that are in the future cannot be minted (until the future, 
 * becomes the present, becomes the past). The oldest date that can be minted is also 
 * limited. Initially, the limit is set to 1900.01.01; however, this limit can be 
 * adjusted in the future to allow the minting of earlier dates. 
 * 
 * The initial minter may submit their statement at the time of minting, or submit it
 * later in a separate transaction, but only while they remain the current Historical 
 * Record owner. The initial minter may also elect to credit a referrer who will 
 * receive a percentage of the minting fee. To receive this referral fee, the referrer 
 * must currently own a Historical Record, and the referrer may not be the minter nor
 * the minting "to" recipient. Referral fees may be withdrawn from this contract by the 
 * referrer using the withdraw function. The minting fee, statement fee, and referral
 * fee percentage are fixed in this contract and cannot be changed.
 *  
 * 
 * Developer details specific to The Historical Record:
 *      uint256 tokenId 
 *          For dates begining in 1970, the tokenId is a Unix time representation of 
 *          the Historical Record date, where only whole day representations are used 
 *          (e.g., 86400 => 1970 Jan 2 00:00). For dates prior to 1970, the tokenId
 *          is equal to -1 times the sum of the equivalent Unix whole day time 
 *          representation, which is a negative value, and 43200 (e.g., 43200 => 1969 
 *          Dec 31 00:00, 129600 => 1969 Dec 30 00:00). Stated programmatically:
 *              If (Unix time) is negative,
 *                  tokenID = -1 * (Unix time + 43200), 
 *              Otherwise,
 *                  tokenID = (Unix time)
 *              Inversely,
 *                  Unix time = ((-1)**(tokenID/43200)) * tokenID - tokenID % 86400
 *      uint256 public oldestRec
 *          oldestRec indicates the oldest Historical Record date that can be minted.
 *          It is a positive value equal to the number of seconds prior to 1970.01.01.
 *          Initially set equal to 1900.01.01, oldestRec will be update in the future
 *          to allow the minting of earlier Historical Record dates.
 *      uint256 public feeBal
 *          feelBal tracks the total referral fees, which may only be withdrawn from 
 *          this contract by the referrers.
 *      uint256 _statementId
 *          _statementId is equal to the tokenId plus the statement number (e.g., the 
 *          _statementId for the first statement for 1970.01.02 would be 86401)
 *      (uint256 tokenId => uint256) public statementCount
 *          The statementCount for each tokenId is tracked. The actual statement count
 *          is always between 0 and 10. 100 is added to statementCount to indicate that
 *          the current owner has already submitted a statement.
 *      (uint256 _statementId => string) public statement
 *          Submitted statements are recorded on-chain (e.g., the first statement for 
 *          1970.01.02 would be mapped as statement[86401]).
 *      (address => uint256) public fees;
 *          Tracks referral fees for each referrer.
 *      event Locked(uint256 indexed tokenId, string _locked);
 *          An event is emitted to denote when a Historical Record is complete (i.e., 
 *          10 statements have been submitted).
 *      event NewStatement(uint256 indexed _statementId, string _statement);
 *          An event is emitted to denote when a new statement is added to a 
 *          Historical Record. 
 *      withdraw()
 *          Allows any user with a referral fee balance to withdraw their fees. 
 *      submitStatement(uint256 tokenId, string memory statement)
 *          Allows tokenId owner to submit a statement.
 *      safeMintRefStatement(address to, uint256 _tokenId, address _ref, string memory 
 *      _statement) 
 *          Allows any user to mint a Historical Record, with the options of crediting
 *          a referrer (_ref) and submitting a first statement. If _tokenId is not an 
 *          acceptable tokenId, _tokenId will be rounded down to the closest acceptable 
 *          tokenId (i.e., tokenId = _tokenId - _tokenId % 43200). A referrer must be a 
 *          current Historical Record owner and may not be the "to", msg.sender, nor 
 *          the zero address.
 *      setoldestRec(uint256 _oldestRec)
 *          Allows contract owner to set oldestRec, which limits the oldest Historical 
 *          Record date that can be minted. 
 *      setbaseURI(string memory _newURI)
 *          Allows contract owner to set the string newURI, which is returned by 
 *          _baseURI(), and which is used as the base URI for the contract and token 
 *          URIs.
 */


// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "IERC2981.sol";   


// For OpenSea
contract OwnableDelegateProxy {}


// For OpenSea
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


/** 
 * @title The Historical Record
 * @author TheHistoricalRecord.ETH
 * @notice This contract allows users to mint and add statements to the
 * Historical Record NFTs. There will only be one Historical Record per 
 * date. Only the current owner may add a statement, and only 10
 * statements may be added per Historical Record.
 */
contract History is ERC721, ERC721Enumerable, Ownable, IERC2981 {
    // See fee for minting
    uint256 constant MINT_FEE = 1e16; //1e16 = 0.01 ether;
    
    // See fee for adding statement
    uint256 constant STATE_FEE = 1e16; //1e16 = 0.01 ether; 

    // Set secondary sale fee divisor
    uint256 constant ROY_FEE = 13; // 1/13 = 7.69%

    // Set minting referral fee divisor
    uint256 constant REF_FEE = 2; // 1/2 = 50%

    // Set baseURI
    string newURI = "https://storage.googleapis.com/the_historical_record/";

    // Total of all referral fees
    uint256 public feeBal;

    // Current limit on oldest Historical Record date
    uint256 public oldestRec = 2208988800;

    // OpenSea proxy address
    address proxyRegistryAddress;

    /**
     * @param _proxyRegistryAddress Address of OpenSea/Wyvern proxy registry
     * On Rinkeby: "0xf57b2c51ded3a29e6891aba85459d600256cf317"
     * On mainnet: "0xa5409ec958c83c3f309868babaca7c86dcb077c1"
     */
    constructor(address _proxyRegistryAddress) 
        ERC721("Historical Record", "HISTORY") 
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
    
    // Locked event indicates when a Historical Record is complete
    event Locked(uint256 indexed tokenId, string _locked);

    // NewStatement event indicates when a Statement is added
    event NewStatement(uint256 indexed _statementId, string _statement);

    // Mappings for tracking Historical Record statements
    mapping (uint256 => uint256) public statementCount;
    mapping (uint256 => string) public statement;

    // Mapping referrer address to referral fees
    mapping(address => uint256) public fees;

    // Withdraw function for referrer fees
    function withdraw() external {
        uint256 _amount = fees[msg.sender];
        fees[msg.sender] = 0;
        feeBal -= _amount;
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent);
    }

    // Withdraw function for owner fees
    function ownerWithdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance - feeBal}("");
        require(sent);
    }

    /**
     * EIP-2981
     * @notice Called with the sale price to determine how much royalty
     * is owed and to whom.
     * @param _salePrice of NFT
     * @dev Note that the empty input is for _tokenId
     * @return receiver Address of who should be sent the royalty payment
     * @return royaltyAmount for a given _salePrice
     */
    function royaltyInfo(uint256, uint256 _salePrice) 
        external 
        view 
        override 
        returns (address receiver, uint256 royaltyAmount) 
    {
        return (owner(), _salePrice / ROY_FEE);
    }

    /**
     * Submit statement to be added to Historical Record. There is no fee to 
     * add the 1st statement, but a fee is required for all subsequent 
     * statements.
     * @param tokenId Unix time representation of a Historical Record date 
     * @param _statement string statement that sender wants added to Record
     * @dev statementCount[tokenId] is set to 100 + the current number of 
     * statements to lock the Record and prevent owner from adding multiple 
     * statements. statementCount[tokenId] is set back equal to the current 
     * number of statements in _beforeTokenTransfer() hook. Submitted 
     * statements are mapped by statement[_statementId].
     */
    function submitStatement(
        uint256 tokenId, 
        string memory _statement
    ) 
        public 
        payable 
    {
        uint256 _statementCount = statementCount[tokenId];
        if (_statementCount > 0) {
            require(msg.value == STATE_FEE, "Incorrect fee");
        }
        require(
            ERC721.ownerOf(tokenId) == msg.sender, 
            "Only owner can add statement"
        );
        require(_statementCount < 10, "Record locked");
        uint256 _statementId = tokenId + _statementCount + 1;
        statement[_statementId] = _statement;
        emit NewStatement(_statementId, _statement);
        if (_statementCount == 9) {
            emit Locked(tokenId, "Record complete");
        }
        statementCount[tokenId] = _statementCount + 101;
    }

    /**
     * Mint a Historical Record with options to credit a referrer and/or to 
     * submit a statement.
     * @param to is the receiver address of the Historical Record
     * @param _tokenId is rounded down to whole day intervals based on Unix 
     * time resulting in tokenID
     * @param _ref is the referrer address. _ref must be a Historical record 
     * owner and may not be "to" nor msg.sender
     * @param _statement string statement that sender wants added to Record
     * @dev tokenID corresponding to dates after 1970 must be less than or 
     * equal to the current block timestamp. tokenID corresponding to dates 
     * before 1970 must be less than or equal to the current limit on oldest 
     * Historical Record date, oldestRec.
     */
    function safeMintRefStatement(
        address to, 
        uint256 _tokenId, 
        address _ref,
        string memory _statement
    ) 
        public 
        payable 
    {
        require(
            msg.value == MINT_FEE ||
            msg.sender == owner(), 
            "Incorrect fee"
        );
        require(
            block.timestamp > 1632326400 || 
            msg.sender == owner(), 
            "Minting not yet open"
        ); //2021.09.22 16:00 UTC
        uint256 tokenId = _tokenId - _tokenId % 43200;
        if (tokenId % 86400 == 0) {
            require(
                tokenId <= block.timestamp, 
                "Cannot mint a Record in future"
            );
        } else {
            require(
                tokenId <= oldestRec, 
                "Record too far in past to mint"
            );
        }
        if (
            _ref != address(0) &&
            _ref != to &&
            _ref != msg.sender &&
            balanceOf(_ref) > 0
        ) 
        {
            uint256 _amount = msg.value / REF_FEE;
            fees[_ref] += _amount;
            feeBal += _amount;
        }
        _safeMint(to, tokenId);
        if (bytes(_statement).length != 0) {
            uint256 _statementId = tokenId + 1;
            statement[_statementId] = _statement;
            emit NewStatement(_statementId, _statement);
            statementCount[tokenId] = 101;
        }
    }

    /**
     * @dev Function to update limit on oldest Historical Record date
     * @param _oldestRec is the oldest date, input as a positive value
     * equal to seconds prior to 1970.01.01
     */
    function setoldestRec(uint256 _oldestRec) public onlyOwner {
        oldestRec=_oldestRec;
    }

    /**
     * @dev Function to update the base URI
     * @param _newURI is the new base URI string
     */
    function setbaseURI(string memory _newURI) public onlyOwner {
        newURI=_newURI;
    }

    // OpenSea Contract URI
    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "OScondata"));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts 
     * to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool) 
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    /**
     * @dev hook to unlock the Record so next statement may be submitted. 
     * Don't allow transfer "to" and "from" same account to prevent same
     * account from submitting multiple consecutive statements.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal override(ERC721, ERC721Enumerable) 
    {
        require(from != to);
        statementCount[tokenId] = statementCount[tokenId] % 100;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Returns base URI for Contract and Token URIs
    function _baseURI() internal view override returns (string memory) {
        return newURI;
    } 
}