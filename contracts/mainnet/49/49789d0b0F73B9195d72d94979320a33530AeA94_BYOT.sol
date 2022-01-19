// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ReEntrancyGuard.sol";
import "./Base64.sol";


contract BYOT is Context, ERC165, IERC721, Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    using Address for address;


    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

        uint256 numFreeMinted = 0;
        uint256 numPurchased = 0;
        uint256 totalSupply = 2500;
        uint256 freeSupply = 500;


         // Mapping from token ID to owner address
        mapping(address => uint256) public mintCredits;

        uint MINT_PRICE = .04 ether; 

  
    
    string[] private hourNums = [
        "1","2","3","4","5","6","7","8","9","10","11","12"
    ];
    
    // 0 AM 1 PM
    uint[] private timeSuffixes = [
        0, 1
    ];
    
    string[] private months = [
        "January", "February", "March", "April", "May", "June",
"July", "August", "September", "October", "November", "December"
    ];
    
    string[] private activities = [
        "Crying","Buying the dip","Panic selling","Buying high, selling low",
        "Watching Jack Dorsey and a16z roast each other","Hodling",
    "Selling all my fiat","Thinking about moving to Miami",
    "Getting rekt","Keeping up with the Kardashians",
    "Changing my pfp","Channeling Pete Davidson energy",
    "Petting Doge", "Serenading the Queen of England",
    "Simping to Drake songs","Figuring out what's in Subway's tuna sandwich",
    "Eating a big ass can of beans","Giving Satan a lap dance",
    "Hitting a blunt with Joe Rogan","Getting into a Twitter fight over Chik-fil-a vs. Popeyes",
    "Getting a pedicure with Elizabeth Warren","On a first date",
    "Buying the constitution","Throwing up on Ken Griffin's shirt",
    "Quitting my job", "Arguing with a Bitcoin maxi",
    "Getting a colonoscopy", "Arm wrestling The Rock", "Shitposting", "Waiting on gas fees to go down",
    "Raising a $100M seed round","Getting wasted"

    ];
    
    string[] private outfits = [
        "My birthday suit", "A Spiderman costume",
        "Socks and sandals", "Crocs",
        "Harry Potter's invisibility cloak",
        "Steve Job's turtleneck", "A grey Patagonia vest",
        "An Oculus headset","Hella sunscreen",
        "Yeezys","Dora's backpack","Bernie Sander's mittens",
        "Timberland boots","A panda onesie","Wolf of Wall Street's suit",
        "A Supreme Hoodie","A Speedo", "Jake from State Farm's sweater",
        "A Gucci belt", "A Ski mask"
    ];
    
    string[] private locations = [
        "On the moon","At karaoke with Voldemort","In the metaverse",
        "On the toilet", "At Olive Garden","In a Prius with Elon Musk",
        "In a pineapple under the sea","In my parents' basement",
        "In Snoop Dogg's mansion","At the SEC Chairman's house",
        "In Scooby Doo's van","On stage at a comedy club",
        "On the subway","In line at TSA","On Lil Yachty's Yacht",
        "At the Grammys","At the Crypto.com Arena","At Times Square",
        "In a billionaire's spaceship","At a funeral home",
        "At a nursing home's Bingo Night","At a Justin Bieber concert",
        "In the 4th dimension","In a Geico commercial"
    ];

    string[] private rarities = [
        "Leap Year", "End of the World",
        "420 B.C.", "42069 A.D.", "1787", "The Big Bang"
    ];
    
    

   

  
  // ERC 721


   /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = BYOT.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = BYOT.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }


    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(BYOT.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(BYOT.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}


 /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }






  /////////////////////

//// BYOT /////////////

  //////////////////////
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getMinutes(uint256 tokenId) public pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("MINUTES", toString(tokenId))));
        uint256 minutesNum = rand % 60;
        if(minutesNum >= 10){
            return string(abi.encodePacked("",toString(minutesNum)));
        }
            return string(abi.encodePacked("0",toString(minutesNum)));
    }

    function getHourNum(uint256 tokenId) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("HOURS", toString(tokenId))));
        uint256 index = rand % hourNums.length;
        return index;
    }
    
    function getHours(uint256 tokenId) public view returns (string memory) {
        uint256 index = getHourNum(tokenId);
        string memory output = hourNums[index];
        return output;
    }
    
    function getTimeSuffixNum(uint256 tokenId) public view returns (uint){
        uint256 rand = random(string(abi.encodePacked("SUFFIX", toString(tokenId))));
        uint suffix = timeSuffixes[rand % timeSuffixes.length];
        return suffix;
    }

    function getTimeSuffix(uint256 tokenId) public view returns (string memory) {
        uint suffix = getTimeSuffixNum(tokenId);
        if(suffix == 0){
            return "AM";
        }
        return "PM";
    }
    
    function getMonth(uint256 tokenId) public view returns (string memory) {
        return getTrait(tokenId, "MONTH", months);
    }

    function getActivity(uint256 tokenId) public view returns (string memory) {
         return getTrait(tokenId, "ACTIVITY", activities);
    }
    
    function getOutfit(uint256 tokenId) public view returns (string memory) {
        return getTrait(tokenId, "OUTFIT", outfits);
    }
    
    function getLocation(uint256 tokenId) public view returns (string memory) {
        return getTrait(tokenId, "LOCATION", locations);
    }
    
  
    function getTrait(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns(string memory){
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function getTimeOfDay(uint256 tokenId) public view returns(string memory) {
        uint256 hourIndex  = getHourNum(tokenId); // index
        uint timeSuffix = getTimeSuffixNum(tokenId);
        // 5 - 12pm -- morning 12 - 7pm ge  -- otherwise night
        if(hourIndex >= 4 && hourIndex < 11 && timeSuffix == 0){
            return "gm";
        } else if((hourIndex == 11 || (hourIndex >=0 && hourIndex < 6)) && timeSuffix == 1){
            return "ge";
        } 
        return "gn";

    }

    function getTime(uint256 tokenId) public view returns(string memory) {
        string memory hour = getHours(tokenId);
        string memory minute = getMinutes(tokenId);
        return string(abi.encodePacked(hour,":",minute));
    }

    function getRarity(uint256 tokenId) internal pure returns(uint256){
        uint256 rand = random(string(abi.encodePacked("RARITY", toString(tokenId))));
        uint256 rarity = rand % 120;
        if(rarity >= 114){
            return 1;
        }
        return 0;
    }

    function getRareTrait(uint256 tokenId) public view returns(string memory) {
        uint256 rarity = getRarity(tokenId);
        if(rarity == 0){
            return "common";
        } else{
            return getTrait(tokenId, "RARITY", rarities);
        }
    }
    

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getTimeOfDay(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getTime(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getTimeSuffix(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getMonth(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getActivity(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getOutfit(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getLocation(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        uint256 rarity = getRarity(tokenId);

        parts[15] = getRareTrait(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        if(rarity == 0){
            output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[16]));
        } else{
            output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14],parts[15],parts[16]));
        }
       
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "BYOT #', toString(tokenId), '", "description": "Buy Your Own Time (BYOT) is a Loot spin-off from the team at The Infinity Collections. The project combines the concept of Loot with the entertaining, sharable quality of Mad Libs. Mint a BYOT and receive a bizarre scenario depicting what you are doing at a moment in time.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

     // only owner can withdraw money deposited in the contract
      function withdraw() external onlyOwner returns(bool){
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
        return true;
    }

    

    function mint(uint256 _toMint) public nonReentrant payable {
        require(_toMint <= 20, "Can only mint a max of 20");
        require(numPurchased.add(_toMint) <= totalSupply.sub(freeSupply), "Will exceed alloted supply");
        require(msg.value >= (_toMint * MINT_PRICE), "Not enough ether sent");
        for(uint256 i = 0; i < _toMint; i++){
             _safeMint(_msgSender(),numPurchased + freeSupply);
            numPurchased = numPurchased.add(1);
            mintCredits[msg.sender] = mintCredits[msg.sender] + 1;
        }
    }

    function freeMint(uint256 _toMint) public nonReentrant {
        require(_toMint <= 20, "Can only mint a max of 20");
        require(numFreeMinted.add(_toMint) <= freeSupply, "Will exceed alloted free supply");
        for(uint256 i = 0; i < _toMint; i++){
             _safeMint(_msgSender(),numFreeMinted);
            numFreeMinted = numFreeMinted.add(1);
            mintCredits[msg.sender] = mintCredits[msg.sender] + 1;
        }
    }

    function getMintCredits(address _owner) external view returns(uint256){
        return mintCredits[_owner];
    }

    function getNumFreeMinted() external view returns(uint256) {
        return numFreeMinted;
    }

    function getNumPurchased() external view returns(uint256) {
        return numPurchased;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        MINT_PRICE  = newPrice;
    }

    function setMaxMint(uint256 newMaxMint) public onlyOwner {
        totalSupply = newMaxMint;
    }
    
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    
}