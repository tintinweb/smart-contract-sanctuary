/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

contract NFTLoan {
    address[16] public loan;
    uint256 item;
    uint256 price;
    uint256 _id;
    bytes32 status;
    string[] public defaults;

    mapping(string => bool) _loanExists;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    //  Adding Loan
    function addingLoan(uint256 loanId) public returns (uint256) {
        require(loanId >= 0 && loanId <= 15);

        loan[loanId] = msg.sender;

        return loanId;
    }

    // Retrieving the loan
    function getLoan() public view returns (address[16] memory) {
        return loan;
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }
    

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length - 1;

        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _mint(address to, uint256 tokenId) private {
        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    // Mint Loan
    function mint(string memory _loan) public {
        require(!_loanExists[_loan]);
        defaults.push(_loan);
        _id = defaults.length -1;
        _mint(msg.sender, _id);
        _loanExists[_loan] = true;
    }
}